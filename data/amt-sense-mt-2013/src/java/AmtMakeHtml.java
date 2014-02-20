import java.io.*;
import java.util.*;

/** AmtMakeHtml
 *  Inputs: 1. word
 *          2. data file
 *          3. name of html dir
 *  Outputs:  3 html pages:
 *              frameset.html, 
 *              frame1: senses,
 *              frame2: sentences
 */


public class AmtMakeHtml {

    public static void main(String[] args) throws IOException {

        if (args.length < 3) {
            System.err.println("args: <word> <datafile> <htmldir>");
            System.exit(-1);
        }

        String word = args[0];
        String dataFilename = args[1];
        File htmlDir = new File(args[2]);

        String sensesFilename = word + "_senses.html";
        File sensesHtml = new File(htmlDir,sensesFilename);

        String sentencesFilename = word + "_setences.html";
        File sentencesHtml = new File(htmlDir,sentencesFilename);

        // create frameset file
        File framesetHtml = new File(htmlDir,word+"_frameset.html");
        BufferedWriter htmlWriter
            = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(framesetHtml),
                                                        "UTF-8"));
        htmlWriter.write("<html>\n<head><title>" 
                         + word
                         +"</title></head>\n");
        htmlWriter.write("<frameset rows=\"20%,80%\">\n");
        htmlWriter.write("<frame src=\"" + sensesFilename + "\">\n");
        htmlWriter.write("<frame src=\"" + sentencesFilename + "\">\n");
        htmlWriter.write("</frameset>\n</html>\n");
        htmlWriter.close();
        
        // read data file, create senses, sentences file on the fly
        boolean inSenses = false;
        boolean inSentences = false;
        BufferedReader reader 
            = new BufferedReader(new InputStreamReader(new FileInputStream(dataFilename),
                                                       "UTF-8"));

        String line = null;
        int lineNum = 0;
        int numSenses = 1; // include category "none of the above"
        while ((line = reader.readLine()) != null) {
            ++lineNum;
            if (lineNum == 1) {
                continue;
            }
            else if (lineNum == 2 && line.startsWith("SENSES")) {
                inSenses = true;
                htmlWriter
                    = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(sensesHtml),
                                                                "UTF-8"));
                htmlWriter.write("<html>\n<body>\n<h2>" + word + " senses</h2>\n<ol>\n");
                continue;
            }
            else if (line.startsWith("SENTENCES")) {
                inSenses = false;
                inSentences = true;
                htmlWriter.write("</ol>\n</body>\n</html>\n");
                htmlWriter.close();
                htmlWriter
                    = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(sentencesHtml),
                                                                "UTF-8"));
                htmlWriter.write("<html>\n<body>\n<h2>" + word + " setences</h2>\n<ol>\n");
                continue;
            }

            if (inSenses) {
                ++ numSenses;
                String[] fields = line.split("\t");
                if (fields.length != 6)
                    throw new IOException("bad data line=" + line + "; line num=" + lineNum);
                htmlWriter.write("<li>" + fields[0] + " <b>" + fields[1] + "</b> " + fields[2] + "<br>\n");
                htmlWriter.write(fields[3] + "\n");

            } else if (inSentences) {
                int idx = line.lastIndexOf(' ');
                String proportion = line.substring(idx);
                line = line.substring(0,idx);
                idx = line.lastIndexOf(' ');
                String votedcat = line.substring(idx);
                line = line.substring(0,idx);
                for (int i=0; i< numSenses; i++) {
                    idx = line.lastIndexOf(' ',idx-1);
                }
                String votes = line.substring(idx);
                line = line.substring(0,idx);
                line = line.replace("[","<br>[");
                htmlWriter.write("<p>" + line + "<br>\n");
                htmlWriter.write("votes: " + votes + " best category: <b>" + votedcat + "</b> proportion: " + proportion + "\n");
            } 
        }
        if (htmlWriter != null) {
            htmlWriter.write("</body>\n</html>\n");
            htmlWriter.close();
        }
        reader.close();
    }
}
