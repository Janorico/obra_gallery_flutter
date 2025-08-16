class Entry {
  int idx;
  String name;
  Manufacturer manufacturer;
  String? productNumber;
  String price;
  PriceType priceType;
  String desc;
  List<Picture> pictures;
  List<Comment> comments;
  String date;

  Entry({
    required this.idx,
    required this.name,
    required this.manufacturer,
    required this.productNumber,
    required this.price,
    required this.priceType,
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
        'manufacturer': String manufacturer,
        'product_number': String? productNumber,
        'price': String price,
        'price_type': String priceType,
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
            manufacturer: Manufacturer.fromString(manufacturer),
            productNumber: productNumber,
            price: price,
            priceType: PriceType.fromString(priceType),
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

enum Manufacturer {
  obra('Obra'),
  lindl('HolzKunst Lindl'),
  holzAuthentisch('Holz Authentisch');

  final String displayName;

  const Manufacturer(this.displayName);

  factory Manufacturer.fromString(String str) {
    for (Manufacturer m in Manufacturer.values) {
      if (m.name == str) return m;
    }
    throw FormatException("No matching manufacturer found for '$str'.");
  }
}

enum PriceType {
  buyable,
  similar,
  bought,
  unbuyable;

  factory PriceType.fromString(String str) {
    for (PriceType pt in PriceType.values) {
      if (pt.name == str) return pt;
    }
    throw FormatException("No matching price type found for '$str'.");
  }
}

class Picture {
  String hash;
  String copyright;
  String fileName;

  Picture({required this.hash, required this.copyright, required this.fileName});

  factory Picture.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {'hash': String hash, 'copyright': String copyright, 'file_name': String fileName} => Picture(hash: hash, copyright: copyright, fileName: fileName),
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
      {'author': String author, 'date': String date, 'text': String text} => Comment(author: author, date: date, text: text),
      _ => throw const FormatException('Failed to parse comment data.'),
    };
  }
}
