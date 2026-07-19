/// ', ' 구분자로 합쳐진 장르 문자열을 리스트로 분해. null/빈 문자열이면 빈 리스트.
List<String> splitGenres(String? genre) =>
    (genre == null || genre.isEmpty) ? const [] : genre.split(', ');
