class Entry {
  int idx;
  String name;
  String desc;
  List<Picture> pictures;
  List<Comment> comments;
  String date;

  Entry({
    required this.idx,
    required this.name,
    required this.desc,
    required this.pictures,
    required this.comments,
    required this.date,
  });

  factory Entry.fromJson(Map<String, dynamic> json) {
    switch (json) {
      case {
        'idx': int idx,
        'name': String name,
        'desc': String desc,
        'pictures': List<dynamic> pictures,
        'comments': List<dynamic> comments,
        'date': String date,
      }:
        {
          List<Picture> p = [];
          for (Map<String, dynamic> item in pictures) {
            p.add(Picture.fromJson(item));
          }
          List<Comment> c = [];
          for (Map<String, dynamic> item in comments) {
            c.add(Comment.fromJson(item));
          }
          return Entry(
            idx: idx,
            name: name,
            desc: desc,
            pictures: p,
            comments: c,
            date: date,
          );
        }
      case _:
        throw const FormatException('Failed to parse entry data.');
    }
  }
}

class Picture {
  String hash;
  String copyright;
  String fileName;

  Picture({
    required this.hash,
    required this.copyright,
    required this.fileName,
  });

  factory Picture.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'hash': String hash,
        'copyright': String copyright,
        'file_name': String fileName,
      } =>
        Picture(hash: hash, copyright: copyright, fileName: fileName),
      _ => throw const FormatException('Failed to parse picture data.'),
    };
  }
}

class Comment {
  String author;
  String date;
  String text;

  Comment({required this.author, required this.date, required this.text});

  factory Comment.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'author': String author,
        'date': String date,
        'text': String text,
      } =>
        Comment(author: author, date: date, text: text),
      _ => throw const FormatException('Failed to parse comment data.'),
    };
  }
}
