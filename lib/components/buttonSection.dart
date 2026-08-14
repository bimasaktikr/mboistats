import 'package:flutter/material.dart';
import 'package:mboistats/datas/button.dart';

class ButtonSection extends StatelessWidget {
  const ButtonSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      margin: EdgeInsets.only(top: 8.0, left: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: mboistatsButton.map((icon) {
            return Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, icon.route);
                  },
                  child: _buildButton(
                      context, icon.title, Colors.blue, icon.route),
                ),
                SizedBox(width: 16.0),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildButton(
      BuildContext context, String text, Color color, String route) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
        ),
      ),
    );
  }
}
