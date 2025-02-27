import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Простой StateProvider для хранения выбранного изображения
final imageProvider = StateProvider<File?>((ref) => null);