FUNCTION getTitle, fname, index
  IF index GT 24 OR index LT 1 THEN return, "UNKNOWN"+strcompress(index)
  openr, un, /get, fname
  line=""
  curVal=-1
  curTitle=""

  WHILE NOT eof(un) AND (curVal NE index) DO BEGIN
     readf, un, line
     tmp=strsplit(line, /extract)
     curVal=fix(tmp[0])
     curTitle=tmp[2:*]
  ENDWHILE

  tmp=""
  FOR i=0,n_elements(curTitle)-1 DO $
     tmp+=curTitle[i]+' '

  close, un
  free_lun, un

  return, tmp
END


pro plotTvXAlt, inputfile, plotfile, colorfile, day, curRes, subsetin, $
                  indexfile, ct=ct, ncover=ncover

  IF strmatch(subsetin, "*.tif") THEN $
    subset=(strsplit(subsetin, '.', /extract))[0] $
    ELSE subset=subsetin
  
  IF NOT keyword_set(ct) THEN ct=29

  data1=read_tiff(inputfile.ndvi)
  data2=read_tiff(inputfile.thermal)

  colordata=read_tiff(colorfile)

  index=where(data1 NE 1 AND data2 NE 1 AND data2 NE -9999 AND colordata NE 16)

  IF index[0] NE -1 THEN BEGIN
     data1=data1[index]
     data2=data2[index]
     colordata=colordata[index]
  ENDIF
;; convert NDVI from 0-20000 -> -1.0-1.0
  data1=(fix(data1)-10000)/10000.0
;; convert thermal from DN to Kelvin
  data2=data2*0.02

  index=where(data1 GT -0.2 AND data2 GT 280 AND data2 LT 340)
  IF index[0] NE -1 THEN BEGIN
     data1=data1[index]
     data2=data2[index]
     colordata=colordata[index]
  ENDIF

  IF n_elements(index) LT 10 THEN return


;; keep track of whether or not we have printed the title yet
  titleNotPrinted=1
  title=string("Day :"+strcompress(day)+ $
               "     Pixel Size :"+strcompress(curRes)+ $
               "km    "+strcompress(subset))

  ncover=5
  ; predefined altitude levels corresponding to groups of 20% of the total pixels
  levels=[10000, 10141, 10377, 10887, 11583, 20000]-10000
  colordata=colordata-10000
  old=setuptvxplot(filename=plotfile)

  !p.multi=[0,2,round(ncover/2.0)]

  npix=n_elements(colordata)
  FOR i=0,ncover-1 DO begin
     index=where(colordata GE levels[i] AND colordata LE levels[i+1])

     IF index[0] NE -1 THEN BEGIN 
        plot, data1[index], data2[index], psym=3, $
              xr=[-0.2,1], yr=[280,340], /xs, /ys, $
              xtitle="NDVI", $
              ytitle="Surface Temperature (K)", $
              title='Elevations :'+strcompress(levels[i])+ ' -'+strcompress(levels[i+1])+ $
                     string(100*n_elements(index)/npix, format='(F5.1)')+'%'
        IF titleNotPrinted THEN BEGIN 
          xyouts, 1.2, 360, title, align=0.5
          titleNotPrinted=0
       ENDIF
    endIF 
  ENDFOR
  
  resetplot, old
  spawn, "pstoimg -density 100 -antialias "+plotfile+" &"
end
