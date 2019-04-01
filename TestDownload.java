import java.net.*;
import java.io.*;

class TestDownload {

    public static void main(String[] args) throws MalformedURLException, IOException {
        URL gradle = new URL("https://services.gradle.org/distributions/gradle-5.2.1-bin.zip");
        BufferedReader in = new BufferedReader(
                new InputStreamReader(gradle.openStream()));

        String inputLine;
        while ((inputLine = in.readLine()) != null);
        in.close();
    }
}