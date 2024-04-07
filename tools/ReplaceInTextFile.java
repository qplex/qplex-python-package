import java.io.File;
import java.io.PrintWriter;
import java.util.Scanner;

public class ReplaceInTextFile {
	public static void main(String args[]) {
		if (args.length != 3) {
			System.err.println("Usage:  filename <replace> <replace-with>");
			System.exit(1);
		}
		
		String filename = args[0];
		String replace = args[1];
		String replaceWith = args[2];
		
		if (!replaceWith.equals(replaceWith.trim())) {
			System.err.println("Leading or trailing whitespace in VERSION.TXT");
			System.exit(1);
		}

		String fileContents;
		
		try {
			fileContents = new Scanner(new File(filename)).useDelimiter("\\Z").next();
			fileContents = fileContents.replace(replace, replaceWith);
			
			PrintWriter out = new PrintWriter(filename);
			out.print(fileContents);
			out.close();
		
			return;
		} catch (Exception x) {
			x.printStackTrace();
			System.exit(1);
		}
	}
}
