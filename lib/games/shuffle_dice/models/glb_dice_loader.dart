import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart' show Color;
import 'package:flutter/services.dart' show rootBundle;

/// Holds the loaded 3D geometry and texture of the dice from `assets/models/dice.glb`
class GlbDiceMesh {
  final List<List<double>> positions; // [ [x, y, z], ... ]
  final List<List<double>> normals;   // [ [nx, ny, nz], ... ]
  final List<ui.Offset> uvs;          // [ Offset(u, v), ... ]
  final List<int> indices;            // 324 indices (108 triangles)
  final ui.Image baseTextureImage;    // 512x512 base texture
  final Uint8List rawGrayscale;       // 512x512 grayscale pixel values
  final int textureWidth;
  final int textureHeight;

  final Map<int, ui.Image> _coloredTextureCache = {};

  GlbDiceMesh({
    required this.positions,
    required this.normals,
    required this.uvs,
    required this.indices,
    required this.baseTextureImage,
    required this.rawGrayscale,
    required this.textureWidth,
    required this.textureHeight,
  });

  /// Returns a recolored texture matching the user's chosen dieColor and dotColor.
  Future<ui.Image> getTextureFor({
    required Color dieColor,
    required Color dotColor,
  }) async {
    final key = dieColor.toARGB32() ^ (dotColor.toARGB32() << 16);
    final cached = _coloredTextureCache[key];
    if (cached != null) {
      return cached;
    }

    final completer = Completer<ui.Image>();
    final pixelBytes = Uint8List(textureWidth * textureHeight * 4);

    final dieR = (dieColor.r * 255).round();
    final dieG = (dieColor.g * 255).round();
    final dieB = (dieColor.b * 255).round();

    final dotR = (dotColor.r * 255).round();
    final dotG = (dotColor.g * 255).round();
    final dotB = (dotColor.b * 255).round();

    // 256-entry lookup table for sub-millisecond mapping
    final lutR = Uint8List(256);
    final lutG = Uint8List(256);
    final lutB = Uint8List(256);

    for (int p = 0; p < 256; p++) {
      final t = ((p - 15) / (221 - 15)).clamp(0.0, 1.0);
      lutR[p] = (dotR + (dieR - dotR) * t).round().clamp(0, 255);
      lutG[p] = (dotG + (dieG - dotG) * t).round().clamp(0, 255);
      lutB[p] = (dotB + (dieB - dotB) * t).round().clamp(0, 255);
    }

    int outIdx = 0;
    for (int i = 0; i < rawGrayscale.length; i++) {
      final p = rawGrayscale[i];
      pixelBytes[outIdx] = lutR[p];
      pixelBytes[outIdx + 1] = lutG[p];
      pixelBytes[outIdx + 2] = lutB[p];
      pixelBytes[outIdx + 3] = 255;
      outIdx += 4;
    }

    ui.decodeImageFromPixels(
      pixelBytes,
      textureWidth,
      textureHeight,
      ui.PixelFormat.rgba8888,
      (image) {
        _coloredTextureCache[key] = image;
        completer.complete(image);
      },
    );

    return completer.future;
  }
}

/// Service to load and cache the 3D dice GLB model
class GlbDiceLoader {
  static GlbDiceMesh? _cached;
  static Future<GlbDiceMesh>? _loadingFuture;

  /// Returns cached mesh if available, or initiates loading.
  static Future<GlbDiceMesh> load() {
    if (_cached != null) {
      return Future.value(_cached);
    }
    _loadingFuture ??= _loadInternal();
    return _loadingFuture!;
  }

  static GlbDiceMesh? get cached => _cached;

  static Future<GlbDiceMesh> _loadInternal() async {
    final byteData = await rootBundle.load('assets/models/dice.glb');
    final bytes = byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );

    // 12-byte header
    // Chunk 0: JSON
    final chunk0Length = byteData.getUint32(12, Endian.little);
    final jsonBytes = bytes.sublist(20, 20 + chunk0Length);
    final gltfJson = jsonDecode(utf8.decode(jsonBytes)) as Map<String, dynamic>;

    // Chunk 1: BIN
    final chunk1Offset = 20 + chunk0Length;
    final chunk1Length = byteData.getUint32(chunk1Offset, Endian.little);
    final binData = bytes.sublist(chunk1Offset + 8, chunk1Offset + 8 + chunk1Length);

    final bufferViews = gltfJson['bufferViews'] as List;
    final accessors = gltfJson['accessors'] as List;
    final meshes = gltfJson['meshes'] as List;
    final nodes = gltfJson['nodes'] as List;
    final prim = (meshes[0]['primitives'] as List)[0] as Map<String, dynamic>;

    // Extract node transform matrix (if present)
    List<double> nodeMatrix = [
      1, 0, 0, 0,
      0, 1, 0, 0,
      0, 0, 1, 0,
      0, 0, 0, 1,
    ];
    if (nodes.isNotEmpty && (nodes[0] as Map<String, dynamic>)['matrix'] != null) {
      final rawM = (nodes[0]['matrix'] as List);
      nodeMatrix = rawM.map((e) => (e as num).toDouble()).toList();
    }

    Uint8List getAccessorBytes(int accIndex) {
      final acc = accessors[accIndex] as Map<String, dynamic>;
      final bvIndex = acc['bufferView'] as int;
      final bv = bufferViews[bvIndex] as Map<String, dynamic>;
      final byteOffset = (bv['byteOffset'] as int? ?? 0) + (acc['byteOffset'] as int? ?? 0);
      final byteLength = bv['byteLength'] as int;
      return binData.sublist(byteOffset, byteOffset + byteLength);
    }

    // 1. Positions
    final posAccIdx = prim['attributes']['POSITION'] as int;
    final posAcc = accessors[posAccIdx] as Map<String, dynamic>;
    final posCount = posAcc['count'] as int;
    final posData = ByteData.sublistView(getAccessorBytes(posAccIdx));

    final positions = <List<double>>[];
    for (int i = 0; i < posCount; i++) {
      final x = posData.getFloat32(i * 12, Endian.little);
      final y = posData.getFloat32(i * 12 + 4, Endian.little);
      final z = posData.getFloat32(i * 12 + 8, Endian.little);
      final tx = nodeMatrix[0] * x + nodeMatrix[4] * y + nodeMatrix[8] * z + nodeMatrix[12];
      final ty = nodeMatrix[1] * x + nodeMatrix[5] * y + nodeMatrix[9] * z + nodeMatrix[13];
      final tz = nodeMatrix[2] * x + nodeMatrix[6] * y + nodeMatrix[10] * z + nodeMatrix[14];
      positions.add([tx, ty, tz]);
    }

    // 2. Normals
    final normAccIdx = prim['attributes']['NORMAL'] as int;
    final normAcc = accessors[normAccIdx] as Map<String, dynamic>;
    final normCount = normAcc['count'] as int;
    final normData = ByteData.sublistView(getAccessorBytes(normAccIdx));

    final normals = <List<double>>[];
    for (int i = 0; i < normCount; i++) {
      final x = normData.getFloat32(i * 12, Endian.little);
      final y = normData.getFloat32(i * 12 + 4, Endian.little);
      final z = normData.getFloat32(i * 12 + 8, Endian.little);
      final tx = nodeMatrix[0] * x + nodeMatrix[4] * y + nodeMatrix[8] * z;
      final ty = nodeMatrix[1] * x + nodeMatrix[5] * y + nodeMatrix[9] * z;
      final tz = nodeMatrix[2] * x + nodeMatrix[6] * y + nodeMatrix[10] * z;
      normals.add([tx, ty, tz]);
    }

    // 3. Texture Coordinates (UVs)
    final uvAccIdx = prim['attributes']['TEXCOORD_0'] as int;
    final uvAcc = accessors[uvAccIdx] as Map<String, dynamic>;
    final uvCount = uvAcc['count'] as int;
    final uvData = ByteData.sublistView(getAccessorBytes(uvAccIdx));

    final uvs = <ui.Offset>[];
    for (int i = 0; i < uvCount; i++) {
      final u = uvData.getFloat32(i * 8, Endian.little);
      final v = uvData.getFloat32(i * 8 + 4, Endian.little);
      uvs.add(ui.Offset(u, v));
    }

    // 4. Indices
    final idxAccIdx = prim['indices'] as int;
    final idxAcc = accessors[idxAccIdx] as Map<String, dynamic>;
    final idxCount = idxAcc['count'] as int;
    final compType = idxAcc['componentType'] as int;
    final idxData = ByteData.sublistView(getAccessorBytes(idxAccIdx));

    final indices = <int>[];
    for (int i = 0; i < idxCount; i++) {
      if (compType == 5125) {
        indices.add(idxData.getUint32(i * 4, Endian.little));
      } else {
        indices.add(idxData.getUint16(i * 2, Endian.little));
      }
    }

    // 5. Decode embedded texture image (Image 0)
    final images = gltfJson['images'] as List;
    final img0 = images[0] as Map<String, dynamic>;
    final imgBvIdx = img0['bufferView'] as int;
    final imgBv = bufferViews[imgBvIdx] as Map<String, dynamic>;
    final imgOffset = imgBv['byteOffset'] as int? ?? 0;
    final imgLength = imgBv['byteLength'] as int;
    final imgBytes = binData.sublist(imgOffset, imgOffset + imgLength);

    final codec = await ui.instantiateImageCodec(imgBytes);
    final frame = await codec.getNextFrame();
    final textureImage = frame.image;

    // Extract raw grayscale values for instant color customization
    final textureByteData = await textureImage.toByteData(format: ui.ImageByteFormat.rawRgba);
    final rawGrayscale = Uint8List(textureImage.width * textureImage.height);
    if (textureByteData != null) {
      for (int i = 0; i < rawGrayscale.length; i++) {
        rawGrayscale[i] = textureByteData.getUint8(i * 4);
      }
    }

    final mesh = GlbDiceMesh(
      positions: positions,
      normals: normals,
      uvs: uvs,
      indices: indices,
      baseTextureImage: textureImage,
      rawGrayscale: rawGrayscale,
      textureWidth: textureImage.width,
      textureHeight: textureImage.height,
    );

    _cached = mesh;
    return mesh;
  }
}
