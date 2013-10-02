import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.Closeable;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.IOException;
import java.io.OutputStream;
import java.io.OutputStreamWriter;

import java.util.Map;
import java.util.LinkedHashMap;

import java.util.zip.GZIPInputStream;

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

        InputStream in = new FileInputStream(args[0]);
        InputStream zipIn = new GZIPInputStream(in);
        BufferedReader reader 
            = new BufferedReader(new InputStreamReader(zipIn,"ASCII"));
        BufferedWriter writer
            = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(args[1]),
                                                        "ASCII"));
        String line;
        int lineNum = 0;
        while ((line = reader.readLine()) != null) {
            ++lineNum;
            if (lineNum == 1) {
                line = line.replaceAll(",","\t");
                writer.write(line + "\n"); // header
                continue;
            }
            String[] fields = line.split(",");
            Integer id = addSymbol(raterMap,fields[1]);
            if (fields.length != 3)
                throw new IOException("bad data line=" + line + "; line num=" + lineNum);
            writer.write(fields[0] + "\t" + id + "\t" + (Integer.valueOf(fields[2]) + 1) + "\n");
        }
        System.out.println("#lines read=" + lineNum);

        close(reader);
        close(zipIn);
        close(in);
        close(writer);

        writer = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(args[2]),
                                                           "ASCII"));
        writer.write("symbol\tid\n");
        for (String key : raterMap.keySet())
            writer.write(key + "\t" + raterMap.get(key) + "\n");
        close(writer);
    }

    static void close(Closeable c) {
        if (c == null) return;
        try {
            c.close();
        } catch (IOException e) {
            // ignore
        }
    }


}

