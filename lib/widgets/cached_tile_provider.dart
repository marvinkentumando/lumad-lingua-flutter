import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CachedTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    String url = getTileUrl(coordinates, options);

    // CartoDB and some other providers use {r} for retina/high-DPI tiles.
    // If it's still in the URL, replace it.
    // We use @2x if the device pixel ratio is > 1.0, otherwise empty.
    if (url.contains('{r}')) {
      url = url.replaceAll('{r}', '');
    }

    return CachedNetworkImageProvider(url);
  }
}


