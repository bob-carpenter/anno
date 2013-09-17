import java.io.*;
import java.util.*;

/** AmtDataMungeAnnotations
 *  Inputs: 1. original file of 5 columns of annotation data
 *          2. name of output directory
 *  Outputs:  multiple data files, 1 file per word
 *  Output 3 columns:  item annotator response
 *  Column 1 input -> name of output file
 *  Columns 2,3 input -> column 1 output ii
 *     output ii = FormId*10 + SentenceId - 1
 *  Column 4 input -> column 2 output
 *     must renumber annotatorIds  1:J, 
 *     output file of mappings -> original id, local id
 *  Column 5 input -> column 3 output
 */

public class AmtDataMungeAnnotations {

    static Integer addSymbol(Map<String,Integer> raterMap, String sym) {
        if (raterMap.containsKey(sym))
            return raterMap.get(sym);
        Integer nextId = raterMap.size() + 1;
        raterMap.put(sym,nextId);
        return nextId;
    }

    public static void main(String[] args) throws IOException {
        Map<String,Integer> raterMap = new LinkedHashMap<String,Integer>();

        String inputFileName = args[0];
        String mungeDirName = args[1];
        BufferedReader reader 
            = new BufferedReader(new InputStreamReader(new FileInputStream(args[0]), 
                                                       "ASCII"));
        BufferedWriter tsvWriter = null;
        String curWord = null;
        String line;
        int lineNum = 0;
        while ((line = reader.readLine()) != null) {
            ++lineNum;
            if (lineNum == 1) {
                continue;
            }
            String[] fields = line.split("\t");
            if (fields.length != 5)
                throw new IOException("bad data line=" + line + "; line num=" + lineNum);
            if (curWord == null || !(fields[0].equals(curWord))) {
                if (curWord != null) {
                    tsvWriter.close();
                    System.out.println("annotators for word " + curWord + ": " + raterMap.size());
                    File curRaters = new File(mungeDirName,curWord+".map");
                    BufferedWriter mapWriter
                        = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(curRaters),
                                                                    "ASCII"));
                    mapWriter.write("amtId\tjj-"+curWord+"\n");
                    for (String key : raterMap.keySet())
                        mapWriter.write(key + "\t" + raterMap.get(key) + "\n");
                    mapWriter.close();
                    raterMap.clear();
                } 
                curWord = fields[0];
                System.out.println("#lines read=" + lineNum);
                System.out.println("processing annotations for word " + curWord);
                File curWordTsv = new File(mungeDirName,curWord+".tsv");
                tsvWriter
                    = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(curWordTsv),
                                                                "ASCII"));
                tsvWriter.write("item\tannotator\trating\n"); // header
            }
            // munge ii - get int value of cols 2,3 (fields 1,2)
            int form = 0;
            int sentence = 0;
            try {
                form = Integer.parseInt(fields[1]);
                sentence = Integer.parseInt(fields[2]);
            } catch (NumberFormatException e) {
                throw new IOException("bad data line=" + line + "; line num=" + lineNum);
            }
            int ii = (form * 10) + sentence - 1;
            Integer jj = addSymbol(raterMap,fields[3]);
            tsvWriter.write(ii + "\t" + jj + "\t" + fields[4] + "\n");
        }
        System.out.println("#lines read=" + lineNum);
        reader.close();

        if (curWord != null) {
            // close current output files
            tsvWriter.close();
            File curRaters = new File(mungeDirName,curWord+".map");
            BufferedWriter mapWriter
                = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(curRaters),
                                                            "ASCII"));
            mapWriter.write("amtId\tjj-"+curWord+"\n");
            for (String key : raterMap.keySet())
                mapWriter.write(key + "\t" + raterMap.get(key) + "\n");
            mapWriter.close();
        }
    }
}
