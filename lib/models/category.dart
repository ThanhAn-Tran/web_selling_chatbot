import 'package:json_annotation/json_annotation.dart';

part 'category.g.dart';

@JsonSerializable()
class Category {
  @JsonKey(name: 'category_id')
  final int id;
  final String name;
  final String? description;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) => _$CategoryFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryToJson(this);
}

@JsonSerializable()
class CreateCategoryRequest {
  final String name;
  final String description;

  CreateCategoryRequest({
    required this.name,
    required this.description,
  });

  factory CreateCategoryRequest.fromJson(Map<String, dynamic> json) => _$CreateCategoryRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateCategoryRequestToJson(this);
}

@JsonSerializable()
class UpdateCategoryRequest {
  final String? name;
  final String? description;

  UpdateCategoryRequest({
    this.name,
    this.description,
  });

  factory UpdateCategoryRequest.fromJson(Map<String, dynamic> json) => _$UpdateCategoryRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateCategoryRequestToJson(this);
} 