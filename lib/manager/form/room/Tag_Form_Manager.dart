class TagFormManager{

  static String listToString(List<String> tags){
    String form = '';

    if(tags.isEmpty){
      return form;
    }

    for(var tag in tags){
      form += '$tag,';
    }

    return form.replaceRange(form.length - 1, null, '');
  }

  static List<String> stringToList(String tag){
    if(tag.isEmpty){
      return [];
    }
    return tag.split(',');
  }
}