import com.sun.tools.javac.Main;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import static java.io.File.pathSeparator;

public class Javac {

    private static String pathString(String first, String... more) {
        return Paths.get(first, more).toString();
    }

    public static void main(String[] args) throws Exception {
        String jdkHome = System.getenv("GRAAL_HOME");
        if (jdkHome == null || jdkHome.trim().isEmpty()) {
            System.err.println("Error: Environment variable GRAAL_HOME missing");
            System.exit(1);
        }
        if (!Files.exists(Paths.get(jdkHome, "jre", "lib", "rt.jar"))) {
            System.err.println("Error: Environment variable GRAAL_HOME points to invalid location");
            System.exit(1);
        }

        // Limited compatibility with Java 11 javac
        ArrayList<String> argsList = new ArrayList<>(Arrays.asList(args));
        for (int i = 0; i < argsList.size() - 1;) {
            if (!"--release".equals(argsList.get(i)) || !"8".equals(argsList.get(i + 1))) {
                i++;
                continue;
            }

            argsList.remove(i);
            argsList.remove(i);

            if (!argsList.contains("-source")) {
                argsList.add("-source");
                argsList.add("8");
            }

            if (!argsList.contains("-target")) {
                argsList.add("-target");
                argsList.add("8");
            }
        }

        System.setProperty("java.class.path", ".");
        System.setProperty("java.endorsed.dirs", 
            pathString(jdkHome, "jre", "lib", "endorsed"));
        System.setProperty("java.ext.dirs", 
            pathString(jdkHome, "jre", "lib", "ext") + pathSeparator + 
            pathString("/usr", "java", "packages", "lib" , "ext"));
        System.setProperty("java.home", pathString(jdkHome, "jre"));
        System.setProperty("sun.boot.class.path", 
            pathString(jdkHome, "jre", "lib", "resources.jar") + pathSeparator +
            pathString(jdkHome, "jre", "lib", "rt.jar") + pathSeparator +
            pathString(jdkHome, "jre", "lib", "sunrsasign.jar") + pathSeparator +
            pathString(jdkHome, "jre", "lib", "jsse.jar") + pathSeparator +
            pathString(jdkHome, "jre", "lib", "jce.jar") + pathSeparator +
            pathString(jdkHome, "jre", "lib", "charsets.jar") + pathSeparator +
            pathString(jdkHome, "jre", "lib", "jfr.jar") + pathSeparator +
            pathString(jdkHome, "jre", "lib", "jvmci-services.jar") + pathSeparator +
            pathString(jdkHome, "jre", "classes") + pathSeparator +
            pathString(jdkHome, "jre", "lib", "boot", "graaljs-scriptengine.jar") + pathSeparator +
            pathString(jdkHome, "jre", "lib", "boot", "graal-sdk.jar") + pathSeparator +
            pathString(jdkHome, "jre", "lib", "boot", "graal-sdk.src.zip"));

        Main.main(argsList.toArray(new String[0]));
    }
}
