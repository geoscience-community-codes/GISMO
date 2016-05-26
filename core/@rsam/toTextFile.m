 function toTextFile(self, filepath)
   % toTextFile(filepath);
    %
    fout=fopen(filepath, 'w');
    for c=1:length(self.dnum)
        fprintf(fout, '%15.8f\t%s\t%5.3e\n',self.dnum(c),datestr(self.dnum(c),'yyyy-mm-dd HH:MM:SS.FFF'),self.data(c));
    end
    fclose(fout);
end