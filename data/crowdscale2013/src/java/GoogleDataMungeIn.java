import java.io.*;
import java.util.*;

public class GoogleDataMungeIn {

    static Integer addSymbol(Map<String,Integer> raterMap, String sym) {
        if (raterMap.containsKey(sym))
            return raterMap.get(sym);
        Integer nextId = raterMap.size() + 1;
        raterMap.put(sym,nextId);
        return nextId;
    }

    // CALL:  <input file> <output file> <sym table file>
    public static void main(String[] args) throws IOException {
        Map<String,Integer> raterMap = new LinkedHashMap<String,Integer>();
        BufferedReader reader 
            = new BufferedReader(new InputStreamReader(new FileInputStream(args[0]), 
                                                       "ASCII"));
        BufferedWriter writer
            = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(args[1]),
                                                        "ASCII"));
        String line;
        int lineNum = 0;
        while ((line = reader.readLine()) != null) {
            ++lineNum;
            if (lineNum == 1) {
                writer.write(line + "\n"); // header
                continue;
            }
            String[] fields = line.split(",");
            Integer id = addSymbol(raterMap,fields[1]);
            if (fields.length != 3)
                throw new IOException("bad data line=" + line + "; line num=" + lineNum);
            writer.write(fields[0] + "," + id + "," + (Integer.valueOf(fields[2]) + 1) + "\n");
        }
        System.out.println("#lines read=" + lineNum);
        
        reader.close();
        writer.close();

        writer = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(args[2]),
                                                           "ASCII"));
        writer.write("symbol,id\n");
        for (String key : raterMap.keySet())
            writer.write(key + "," + raterMap.get(key) + "\n");
        writer.close();
    }

}

