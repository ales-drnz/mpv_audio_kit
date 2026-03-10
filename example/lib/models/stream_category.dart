class StreamItem {
  final String label;
  final String url;
  const StreamItem({required this.label, required this.url});
}

class StreamCategory {
  final String name;
  final List<StreamItem> items;
  const StreamCategory({required this.name, required this.items});
}
