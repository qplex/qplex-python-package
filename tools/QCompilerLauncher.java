import java.io.File;
import java.util.ArrayList;

public class QCompilerLauncher {
	static void abort(String message) {
		System.err.println(message);
		System.exit(1);
	}
	
	public static void main(String args[]) {
		File[] files = new File(".").listFiles();
		ArrayList<String> engines = new ArrayList<String>();
	
		for (File file : files) {
			String name = file.getName();
			if (name.endsWith(".q"))
				engines.add(name);
		}
		
		if (engines.isEmpty())
			abort("No q-files found.");
		
		engines.add(0, "qplex");
		String newArgs[] = new String[engines.size()];
		engines.toArray(newArgs);

		QCompiler.main(newArgs);
	}
}
