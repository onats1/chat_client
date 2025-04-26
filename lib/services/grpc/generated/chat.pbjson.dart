//
//  Generated code. Do not modify.
//  source: chat.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use chatMessageDescriptor instead')
const ChatMessage$json = {
  '1': 'ChatMessage',
  '2': [
    {'1': 'userId', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'content', '3': 2, '4': 1, '5': 9, '10': 'content'},
    {'1': 'timestamp', '3': 3, '4': 1, '5': 3, '10': 'timestamp'},
  ],
};

/// Descriptor for `ChatMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chatMessageDescriptor = $convert.base64Decode(
    'CgtDaGF0TWVzc2FnZRIWCgZ1c2VySWQYASABKAlSBnVzZXJJZBIYCgdjb250ZW50GAIgASgJUg'
    'djb250ZW50EhwKCXRpbWVzdGFtcBgDIAEoA1IJdGltZXN0YW1w');

