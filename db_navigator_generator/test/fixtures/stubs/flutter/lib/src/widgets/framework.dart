typedef VoidCallback = void Function();

abstract class Key {
  const Key();
}

abstract class BuildContext {}

abstract class Widget {
  const Widget({this.key});

  final Key? key;
}

abstract class StatelessWidget extends Widget {
  const StatelessWidget({super.key});

  Widget build(BuildContext context);
}

abstract class StatefulWidget extends Widget {
  const StatefulWidget({super.key});
}

class Text extends StatelessWidget {
  const Text(this.data, {super.key});

  final String data;

  @override
  Widget build(BuildContext context) => this;
}
