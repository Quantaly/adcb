import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:resource_portable/resource.dart';

void main(List<String> arguments) async {
  var args = (ArgParser()
        ..addOption(
          'prefix',
          abbr: 'p',
          help: 'The prefix to use for the component tag',
          defaultsTo: 'my',
        )
        ..addOption(
          'style',
          abbr: 's',
          help: 'The type of stylesheet to use',
          allowed: ['css', 'scss', 'sass'],
          defaultsTo: 'scss',
        )
        ..addOption(
          'dir',
          abbr: 'd',
          help: 'The directory to generate the component directory into',
          defaultsTo: 'lib/src/components',
        ))
      .parse(arguments);

  var prefix = args['prefix'];
  var style = args['style'];
  var dir = args['dir'];
  var name = args.rest[0];
  var fileName = fileNameFromName(name);
  var className = classNameFromName(name);

  var filler = fillTemplate(
      prefix: prefix, name: name, fileName: fileName, className: className);

  await Future.wait([
    Resource('package:adcb/dart.template').readAsString().then(filler).then(
        (text) => saveFile(text, dir: dir, fileName: fileName, type: 'dart')),
    Resource('package:adcb/html.template').readAsString().then(filler).then(
        (text) => saveFile(text, dir: dir, fileName: fileName, type: 'html')),
    Resource('package:adcb/$style.template').readAsString().then(filler).then(
        (text) => saveFile(text, dir: dir, fileName: fileName, type: style)),
  ]);
}

String fileNameFromName(String name) {
  return name.replaceAll('-', '_');
}

String classNameFromName(String name) {
  name = name.substring(0, 1).toUpperCase() + name.substring(1);
  int i;
  while ((i = name.indexOf('-')) >= 0) {
    name = name.substring(0, i) +
        name.substring(i + 1, i + 2).toUpperCase() +
        name.substring(i + 2);
  }
  return name;
}

String Function(String) fillTemplate(
    {String prefix, String name, String fileName, String className}) {
  return (template) {
    var ret = template.replaceAll('PREFIX', prefix);
    ret = ret.replaceAll('FILENAME', fileName);
    ret = ret.replaceAll('CLASSNAME', className);
    ret = ret.replaceAll('NAME', name);
    return ret;
  };
}

Future<void> saveFile(String text,
    {String dir, String fileName, String type}) async {
  var path = p.join(dir, '$fileName.$type');
  var outfile = File(path);
  await outfile.create(recursive: true);
  await outfile.writeAsString(text);
}
