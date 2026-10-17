// MIT. APK de prueba propio: las respuestas y el contador se calculan en código nativo.
package cl.miao.nativeprobe;
import android.app.Activity;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;
public class MainActivity extends Activity {
 static { System.loadLibrary("miao_test"); }
 private static native String nativeAbi();
 private static native int increment();
 @Override public void onCreate(Bundle state) {
  super.onCreate(state);
  LinearLayout box=new LinearLayout(this);box.setOrientation(LinearLayout.VERTICAL);box.setPadding(32,60,32,32);
  TextView title=new TextView(this);title.setText("Prueba nativa de Mi Android Online");title.setTextSize(22);box.addView(title);
  TextView arch=new TextView(this);arch.setText("ABI nativa: "+nativeAbi());arch.setTextSize(20);box.addView(arch);
  final TextView counter=new TextView(this);counter.setText("Contador nativo: 0");counter.setTextSize(24);box.addView(counter);
  Button add=new Button(this);add.setText("Sumar");add.setAllCaps(false);
  add.setOnClickListener(new View.OnClickListener(){public void onClick(View v){counter.setText("Contador nativo: "+increment());}});
  box.addView(add);setContentView(box);
 }
}
