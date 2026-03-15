class StreamItem {
  final String label;
  final String url;
  final Map<String, dynamic>? extras;
  final Map<String, String>? httpHeaders;

  const StreamItem({
    required this.label,
    required this.url,
    this.extras,
    this.httpHeaders,
  });
}

class StreamCategory {
  final String name;
  final List<StreamItem> items;
  const StreamCategory({required this.name, required this.items});
}
