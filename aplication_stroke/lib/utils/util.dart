/// Mengubah format teks menjadi Title Case (Huruf Besar di Awal Kata).
/// Contoh: "hello world" -> "Hello World".
String capitalizeWords(String name) {
  if (name.isEmpty) return "";

  return name
      .split(' ')
      .map(
        (word) => word
            .split(".")
            .map(
              (part) => part.isNotEmpty
                  ? part[0].toUpperCase() + part.substring(1).toLowerCase()
                  : '',
            )
            .join("."),
      )
      .join(" ");
}

