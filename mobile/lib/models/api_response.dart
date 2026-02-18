class ApiResponse<T> {
  ApiResponse._({required this.success, this.data, this.error});

  factory ApiResponse.success(T data) =>
      ApiResponse._(success: true, data: data);

  factory ApiResponse.error(String message) =>
      ApiResponse._(success: false, error: message);

  final bool success;
  final T? data;
  final String? error;
}
