import ddf.minim.*;

Minim minim;
AudioPlayer voicePlayer;
AudioPlayer accPlayer;
AudioSample ban;
AudioSample gu;

String zhFontFile = "simkai.ttf";
String enFontFile = "Roboto-Regular.ttf";
PFont zhFont;
PFont enFont;
String titleFile = "sections/lsaria-title.csv";
Table titleTable;
String title;
String banshiFile = "sections/lsaria-banshi.csv";
Table banshiTable;
String[] banshi;
int[] banshiStart;
int[] banshiEnd;
int[] bIndex; // banshi index
int banshiIndex;
String linesFile = "sections/lsaria-line.csv";
Table linesTable;
String[] lines;
int[] linesStart;
int[] linesEnd;
int[] lIndex; // lines index
int[] linesBanshi;
String tempoFile = "lsaria_tempocurve.csv";
Table tempoData;
int[] tempoTime;
float[] tempoValue;
int[] beat;
int[] index; // tempo index
int tempoIndex;
PShape tempoCurve;
boolean click = false;
float tempoMin;
float tempoMax;
int tempoBoxX = 20;
int tempoBoxH = 80;
int banshiHeaderH = 15;
int tms = 15; // tempo marker size
int tmY = tempoBoxX+tempoBoxH+tms+10; // to be subtracted from height
int tlX; // tempo light x
int tlY; // tempo light y
int tlr = 7; // tempo light radius
int tld; // tempo light duration
int lyricsBoxX = 150;
int lyricsBoxY = 120;
int tempLyrSp = 20; // vertical space between tempo and lyrics boxes
int lyricsBoxH = lyricsBoxY+tempoBoxX+tempoBoxH+tempLyrSp; // to be subtracted from height
int lineSize = 15;
int lineAdjust = 10;
int lineShift = lineSize+lineAdjust;
int linesSkip = 0;
int skipTop;
int skipBottom;
int skipBarH = 20;
int butRad = 17; // buttons radius
int playX = tempoBoxX+butRad;
int playY = lyricsBoxY+butRad;
int stopX = playX + 2*butRad + 10;
int stopY = playY;
int sourceW = 60;
float sourceH = (sourceW * 287) / 168;
int voiceX = tempoBoxX;
int voiceY = playY+butRad+20;
int accX = tempoBoxX;
float accY = voiceY + sourceH + 20;
String voiceFile = "lsvoice.mp3";
String accFile = "lsacc.mp3";
String banFile = "ban.mp3";
String guFile = "gu.mp3";
PImage voiceImg;
PImage accImg;
float accVol = 0;
float voiceVol = 0;
int volMax = 20;
int volMin = -40;
float voiceVolY;
float accVolY;
int volButtonW = 15;
int volButtonH = 10;
int vol0Line = volButtonW/2 + 3; // pixels longer than the button
int ssd = 15; // source-slider distance
int sliderW = 3;
int latency = 300;

void setup() {
  frameRate(10000);
  size(1080, 720);
  ellipseMode(RADIUS);
  
  zhFont = createFont(zhFontFile, 50);
  enFont = createFont(enFontFile, 50);
  
  // Title and sections
  titleTable = loadTable(titleFile);
  title = titleTable.getString(0, 0);
  
  linesTable = loadTable(linesFile);
  lines = new String[linesTable.getRowCount()];
  linesStart = new int[linesTable.getRowCount()];
  linesEnd = new int[linesTable.getRowCount()];
  for (int i = 0; i < linesTable.getRowCount(); i++) {
    lines[i] = linesTable.getString(i, 0);
    linesStart[i] = int(linesTable.getFloat(i, 1) * 1000);
    linesEnd[i] = int(linesTable.getFloat(i, 2) * 1000);
  }
  
  banshiTable = loadTable(banshiFile);
  banshi = new String[banshiTable.getRowCount()];
  banshiStart = new int[banshiTable.getRowCount()];
  banshiEnd = new int[banshiTable.getRowCount()];
  for (int i = 0; i < banshiStart.length; i++) {
    banshi[i] = banshiTable.getString(i, 0);
    banshiStart[i] = int(banshiTable.getFloat(i, 1) * 1000);
    banshiEnd[i] = int(banshiTable.getFloat(i, 2) * 1000);
  }
  
  linesBanshi = new int[linesStart.length];
  int bi = 0; // banshi index
  for (int i = 0; i < linesStart.length; i++) {
    if ((linesStart[i] >= banshiStart[bi]) && (linesEnd[i] <= banshiEnd[bi])) {
      linesBanshi[i] = bi;
    } else {
      bi++;
      linesBanshi[i] = bi; 
    }
  }
  
  // Tempo arrays
  tempoData = loadTable(tempoFile);
  tempoTime = new int[tempoData.getRowCount()+2];
  tempoValue = new float[tempoData.getRowCount()+2];
  beat = new int[tempoData.getRowCount()+2];
  for (int i = 0; i < tempoData.getRowCount(); i++) { 
    tempoTime[i+1] = int(tempoData.getFloat(i, 0)*1000);
    tempoValue[i+1] = tempoData.getFloat(i, 1);
    float b = tempoData.getFloat(i, 2); // converts the beat value into string
    if (b % 1 > 0) {
      beat[i+1] = int(str(b).charAt(str(b).length()-1))-48;
    } else {
      beat[i+1] = 1;
    }
  }
  tempoTime[0] = 0;
  tempoValue[0] = 0.0;
  beat[0] = 0;
  tempoTime[tempoTime.length-1] = tempoTime[tempoTime.length-2] + latency;
  tempoValue[tempoValue.length-1] = 0.0;
  beat[beat.length-1] = 0;
  
  float temporalMin = 300; 
  for (int i = 0; i < tempoValue.length; i++) {
    if ((tempoValue[i] != 0) && (tempoValue[i] < temporalMin)) {
      temporalMin = tempoValue[i];
    }
  }
  tempoMin = temporalMin - 20;
  tempoMax = max(tempoValue) + 20;
  
  // Set audio
  minim = new Minim(this);
  voicePlayer = minim.loadFile(voiceFile);
  accPlayer = minim.loadFile(accFile);
  ban = minim.loadSample(banFile);
  ban.setGain(5);
  gu = minim.loadSample(guFile);
  gu.setGain(-7);
  
  // Tempo curve
  int curveWeight = 2;
  tempoCurve = createShape();
  tempoCurve.beginShape();
  tempoCurve.noFill();
  tempoCurve.stroke(100);
  tempoCurve.strokeWeight(curveWeight);
  for (int i = 0; i < tempoValue.length; i++) {
    float x = map(tempoTime[i], 0, voicePlayer.length(), tempoBoxX, width-tempoBoxX);
    float y;
    if (tempoValue[i] == 0) {
      y = map(tempoMin, tempoMin, tempoMax+banshiHeaderH, height-tempoBoxX, height-tempoBoxH-tempoBoxX)-curveWeight;
    } else {
      y = map(tempoValue[i], tempoMin, tempoMax, height-tempoBoxX, height-tempoBoxH-tempoBoxX+banshiHeaderH);
    }
    tempoCurve.vertex(x, y);
  }
  tempoCurve.endShape();
  
  // Time index
  index = new int[voicePlayer.length()];
  for (int i = 0; i < tempoTime.length; i++) {
    index[tempoTime[i]] = i;
  }
  int j = 0;
  for (int i = 0; i < index.length; i++) {
    if (index[i] == 0) {
      index[i] = j;
    } else {
      j = index[i];
    }
  }
  
  // Banshi index
  bIndex = new int[voicePlayer.length()];
  for (int i = 0; i < banshiEnd.length; i++) {
    bIndex[banshiEnd[i]] = -1;
  }
  for (int i = 0; i < banshiStart.length; i++) {
    bIndex[banshiStart[i]] = i+1;
  }
  int b = 0;
  for (int i = 0; i < bIndex.length; i++) {
    if (bIndex[i] == 0) {
        bIndex[i] = b;
    } else {
        b = bIndex[i];
    }
  }
  
  // Lines index
  lIndex = new int[voicePlayer.length()];
  for (int i = 0; i < linesEnd.length; i++) {
    lIndex[linesEnd[i]] = -1;
  }
  for (int i = 0; i < linesStart.length; i++) {
    lIndex[linesStart[i]] = i+1;
  }
  int l = 0;
  for (int i = 0; i < lIndex.length; i++) {
    if (lIndex[i] == 0) {
        lIndex[i] = l;
    } else {
        l = lIndex[i];
    }
  }
  
  // Fit lines in the lyrics box
  int maxLines = int((height-lyricsBoxH) / lineShift);
  if (linesStart.length > maxLines) {
    linesSkip = linesStart.length - maxLines;
  }
  
  voiceImg = loadImage("voice.png");
  accImg = loadImage("jinghu.png");
}

void draw() {
  background(250, 209, 159);
  
  // title
  textFont(zhFont);
  textSize(30);
  fill(0);
  text(title, 20, 50);
  
  // Volume
  voicePlayer.setGain(voiceVol);
  accPlayer.setGain(accVol);
  
  // Player buttons
  stroke(0);
  strokeWeight(1);
  // Play button
  if (voicePlayer.isPlaying()) {
    fill(0, 150, 0);
  } else {
    fill(0, 255, 0);
  }
  ellipse(playX, playY, butRad, butRad);
  // Stop button
  if (!voicePlayer.isPlaying() && voicePlayer.position() == 0) {
    fill(70, 0, 0);
  } else {
    fill(255, 0, 0);
  }
  ellipse(stopX, stopY, butRad, butRad);
  
  // Source buttons
  // Background and images
  noStroke();
  fill(206, 167, 123);
  rect(voiceX, voiceY, sourceW, sourceH);
  image(voiceImg, voiceX, voiceY, sourceW, sourceH);
  rect(accX, accY, sourceW, sourceH);
  image(accImg, accX, accY, sourceW, sourceH);
  // Mute shadow
  stroke(0);
  strokeWeight(1);
  if (voicePlayer.isMuted()) {
    fill(0, 100);
  } else {
    noFill();
  }
  rect(voiceX, voiceY, sourceW, sourceH);
  if (accPlayer.isMuted()) {
    fill(0, 100);
  } else {
    noFill();
  }
  rect(accX, accY, sourceW, sourceH);
  // Volume slides
  float voiceVolume0Y = map(0, volMax, volMin, voiceY, voiceY+sourceH);
  float accVolume0Y = map(0, volMax, volMin, accY, accY+sourceH);
  stroke(0);
  int voiceVolumeFill = int(map(voiceVol, volMax, volMin, 255, 0));
  fill(voiceVolumeFill);
  rect(voiceX+sourceW+ssd, voiceY, sliderW, sourceH);
  line(voiceX+sourceW+ssd-vol0Line, voiceVolume0Y, voiceX+sourceW+ssd+sliderW+vol0Line, voiceVolume0Y); 
  int accVolumeFill = int(map(accVol, volMax, volMin, 255, 0));
  fill(accVolumeFill);  
  rect(accX+sourceW+ssd, accY, sliderW, sourceH);
  line(accX+sourceW+ssd-vol0Line, accVolume0Y, accX+sourceW+ssd+sliderW+vol0Line, accVolume0Y);
  // Volume slide button
  stroke(0);
  strokeWeight(1);
  fill(206, 167, 123);
  voiceVolY = map(voiceVol, volMax, volMin, voiceY, voiceY+sourceH);
  rect(voiceX+sourceW+ssd+sliderW/2-volButtonW/2, voiceVolY-volButtonH/2, volButtonW, volButtonH);
  accVolY = map(accVol, volMax, volMin, accY, accY+sourceH);
  rect(accX+sourceW+ssd+sliderW/2-volButtonW/2, accVolY-volButtonH/2, volButtonW, volButtonH);
  
  // Lirycs box background
  int lyricsBoxW = width-lyricsBoxX-tempoBoxX;
  noStroke();
  fill(206, 167, 123);
  rect(lyricsBoxX, lyricsBoxY, lyricsBoxW, height-lyricsBoxH);
    
  // Tempo box background
  noStroke();
  fill(206, 167, 123);
  rect(tempoBoxX, height-tempoBoxX-tempoBoxH, width-(2*tempoBoxX), tempoBoxH);
  
  // Tempo marker
  int tempoInstant = voicePlayer.position();
  String tempoMark;
  textFont(enFont);
  fill(0);
  textSize(tms);
  if (tempoValue[index[tempoInstant]] == 0) {
    tempoMark = "Scattered";
  } else {
    tempoMark = nf(tempoValue[index[tempoInstant]], 3, 1) + " bpm"; 
  }
  text(tempoMark, tempoBoxX, height-tmY, tms*5, tms+4);
  
  // Tempo light
  stroke(0);
  strokeWeight(1);
  int instantIndex = index[tempoInstant];
  if (instantIndex != tempoIndex) {
    tld = tempoInstant + latency;
    tempoIndex = instantIndex;
    click = true;
  } else {
    click = false;
  }
  int beatType = beat[index[tempoInstant]];
  if ((tempoInstant < tld) && (beatType == 1) && voicePlayer.isPlaying()) {
    fill(255, 0, 0);
    if (click) ban.trigger();
  } else if ((tempoInstant < tld) && (beatType != 1) && (beatType != 0) && voicePlayer.isPlaying()) {
    fill(0, 255, 0);
    if (click) gu.trigger();
  } else {
    fill(100);
  }
  tlX = tempoBoxX + 105;
  tlY = tmY-tlr;
  ellipse(tempoBoxX+tms*5+tlr, height-tmY+(tms+4)/2, tlr, tlr);
  
  // Lines boxes...
  int lineX = lyricsBoxX+lineAdjust;
      int tX = lyricsBoxX+lyricsBoxW/2; // triangle X
  // Omitting lines if more than possible in the box
  if (linesSkip > 0) {
    noStroke();
    if (tempoInstant > linesStart[linesStart.length-linesSkip-1]) {
      skipTop = linesSkip;
      skipBottom = 0;
      // skip bar
      fill(100, 50);
      rect(lyricsBoxX, lyricsBoxY, lyricsBoxW, skipBarH);
      float tY1 = lyricsBoxY+skipBarH*0.2; // triangle Y
      float tY2 = lyricsBoxY+skipBarH*0.8; // triangle Y
      fill(0, 100);
      triangle(tX, tY1, tX-(skipBarH*0.8)/2, tY2, tX+(skipBarH*0.8)/2, tY2);
    } else {
      skipBottom = linesSkip;
      skipTop = 0;
      // skip bar
      int skipBarY = height-tempoBoxX-tempoBoxH-tempLyrSp-skipBarH;
      fill(100, 50);
      rect(lyricsBoxX, skipBarY, lyricsBoxW, skipBarH);
      float tY1 = skipBarY+skipBarH*0.2; // triangle Y
      float tY2 = skipBarY+skipBarH*0.8; // triangle Y
      fill(0, 100);
      triangle(tX, tY2, tX-(skipBarH*0.8)/2, tY1, tX+(skipBarH*0.8)/2, tY1);
    }
  }
  // ...in lyrics box
  for (int i = skipTop; i < linesStart.length-skipBottom; i++) {
    if (lIndex[tempoInstant] == i+1) {
      noStroke();
      fill(255, 128, 0, 150);
      float lineBoxX = lyricsBoxX+lineSize*8+lineAdjust;
      float lineBoxY = lyricsBoxY+lineShift*(i-skipTop+1)-lineSize-lineAdjust/3;
      rect(lineBoxX, lineBoxY, width-lineBoxX-tempoBoxX, lineSize+lineAdjust);
    }
  }
  // ...in tempo box
  for (int i = 0; i < linesStart.length; i++) {
    float boxX = map(linesStart[i], 0, voicePlayer.length(), tempoBoxX, width-tempoBoxX);
    float boxW = map(linesEnd[i], 0, voicePlayer.length(), tempoBoxX, width-tempoBoxX) - boxX;
    if (lIndex[tempoInstant] == i+1) {
      fill(255, 128, 0, 150);
    } else {
      fill(150, 150);
    }
    stroke(206, 167, 123);
    strokeWeight(1);
    rect(boxX, height-tempoBoxX-tempoBoxH, boxW, tempoBoxH);
  }
  
  // Banshi boxes...
  // ...in lyrics box
  int currentBanshi = -1;
  int bbYi = -1; // banshi box Y index
  int bbHi = 0; // banshi box height index
  for (int i = skipTop; i < linesBanshi.length-skipBottom; i++) {
    if (linesBanshi[i] != currentBanshi) {
      if (bbHi > 0) {
        float banshiBoxY = lyricsBoxY+lineShift*(bbYi-skipTop+1)-lineSize-lineAdjust/3;
        if (bIndex[tempoInstant] == linesBanshi[i]) {
          fill(255, 128, 0, 150);
        } else {
          noFill();
        }
        noStroke();
        rect(lyricsBoxX, banshiBoxY, lineSize*8+lineAdjust, (lineShift)*bbHi);
        bbHi = 1;
      } else {
        bbHi++;
      }
      currentBanshi = linesBanshi[i];
      bbYi = i;
    } else {
      bbHi++;
    }
  }
  float banshiBoxY = lyricsBoxY+lineShift*(bbYi-skipTop+1)-lineSize-lineAdjust/3;
  if (bIndex[tempoInstant] == linesBanshi[linesBanshi.length-skipBottom-1]+1) {
    fill(255, 128, 0, 150);
  } else {
    noFill();
  }
  rect(lyricsBoxX, banshiBoxY, lineSize*8+lineAdjust, (lineShift)*bbHi);
  //...in tempo box
  for (int i = 0; i < banshiStart.length; i++) {
    float banshiHeaderX = map(banshiStart[i], 0, voicePlayer.length(), tempoBoxX, width-tempoBoxX);
    float banshiHeaderW = map(banshiEnd[i], 0, voicePlayer.length(), tempoBoxX, width-tempoBoxX)-banshiHeaderX;
    stroke(206, 167, 123);
    strokeWeight(1);
    if (bIndex[tempoInstant] == i+1) {
      fill (255, 128, 0, 150);
    } else {
      fill(0, 50);
    }
    rect(banshiHeaderX, height-tempoBoxX-tempoBoxH, banshiHeaderW, banshiHeaderH);
    fill(0);
    if (banshi[i].length()*banshiHeaderH*0.75 < banshiHeaderW) {
      textFont(zhFont);
      textSize(banshiHeaderH*0.75);
      text(banshi[i], banshiHeaderX+banshiHeaderH*0.05, height-tempoBoxX-tempoBoxH+banshiHeaderH*0.8);
    } else {
      textFont(enFont);
      textSize(banshiHeaderH*0.75);
      text("#"+str(i+1), banshiHeaderX+banshiHeaderH*0.05, height-tempoBoxX-tempoBoxH+banshiHeaderH*0.8);
    }
  }
  
  // Banshi
  textFont(zhFont);
  fill(0);
  textSize(lineSize);
  int newBanshi = -1;
  for (int i = skipTop; i < linesBanshi.length-skipBottom; i++) {
    if (linesBanshi[i] != newBanshi) {
      text(banshi[linesBanshi[i]], lineX, lyricsBoxY+lineShift*(i-skipTop+1));
      newBanshi = linesBanshi[i];
    }
  }
  
  // Banshi | lines separation line
  stroke(0, 150);
  strokeWeight(1);
  line(lineX+lineSize*8, lyricsBoxY+lineAdjust, lineX+lineSize*8, height-lyricsBoxH-lineAdjust+lyricsBoxY);  
  
  // Lyrics lines
  textFont(zhFont);
  textSize(lineSize);
  fill(0);
  for (int i = skipTop; i < lines.length-skipBottom; i++) {
    text(lines[i], lineX+lineSize*8+lineAdjust, lyricsBoxY+lineShift*(i-skipTop+1));
  }
  
  // Draw tempo curve
  shape(tempoCurve, 0, 0);
  
  // Cursor
  float pos = voicePlayer.position();
  float cursorX = map(pos, 0, voicePlayer.length(), tempoBoxX+2, width-tempoBoxX-2);
  stroke(240, 245, 12);
  strokeWeight(3);
  line(cursorX, height-tempoBoxX-tempoBoxH, cursorX, height-tempoBoxX);
  
  // Lyrics box border  
  stroke(0);
  strokeWeight(1);
  noFill();
  rect(lyricsBoxX, lyricsBoxY, lyricsBoxW, height-lyricsBoxH);
  
  // Tempo curve box border
  stroke(0);
  strokeWeight(1);
  noFill();
  rect(tempoBoxX, height-tempoBoxX-tempoBoxH, width-(2*tempoBoxX), tempoBoxH);
}
  
void mouseClicked() {
  // Play button
  if (dist(mouseX, mouseY, playX, playY) < butRad) {
    if (voicePlayer.isPlaying()) {
      voicePlayer.pause();
      accPlayer.pause();
    } else {
      voicePlayer.play();
      accPlayer.play();
    }
  // Stop button
  } else if (dist(mouseX, mouseY, stopX, stopY) < butRad && 
             voicePlayer.position() > 0) {
    voicePlayer.pause();
    voicePlayer.rewind();
    accPlayer.pause();
    accPlayer.rewind();
  // Voice button
  } else if ((mouseX > voiceX) && (mouseX < voiceX+sourceW) &&
             (mouseY > voiceY) && (mouseY < voiceY+sourceH)) {
    if (voicePlayer.isMuted()) {
      voicePlayer.unmute();
    } else {
      voicePlayer.mute();
    }
  // Acc button
  } else if ((mouseX > accX) && (mouseX < accX+sourceW) &&
             (mouseY > accY) && (mouseY < accY+sourceH)) {
    if (accPlayer.isMuted()) {
      accPlayer.unmute();
    } else {
      accPlayer.mute();
    }
  // Tempo box
  } else if ((mouseX > tempoBoxX) && (mouseX < width-tempoBoxX) &&
             (mouseY > height-tempoBoxX-tempoBoxH) &&
             (mouseY < height-tempoBoxX)) {
      int currentPos = voicePlayer.position();
      int targetPos = int(map(mouseX, tempoBoxX, width-tempoBoxX, 0, voicePlayer.length()));
      int jump = targetPos - currentPos; 
      voicePlayer.skip(jump);
      accPlayer.skip(jump);
  // Voice volume
  } else if ((mouseX > voiceX+sourceW+ssd+sliderW/2-volButtonW/2) && (mouseY > voiceY) &&
             (mouseX < voiceX+sourceW+ssd+sliderW/2+volButtonW/2) && (mouseY < voiceY+sourceH)) {
    voiceVol = map(mouseY, voiceY, voiceY+sourceH, volMax, volMin);
  // Acc volume
  } else if ((mouseX > accX+sourceW+ssd+sliderW/2-volButtonW/2) && (mouseY > accY) &&
             (mouseX < accX+sourceW+ssd+sliderW/2+volButtonW/2) && (mouseY < accY+sourceH)) {
    accVol = map(mouseY, accY, accY+sourceH, volMax, volMin);
  // Tempo light
  } else if (dist(mouseX, mouseY, tlX, tlY) < tlr) {
    if (ban.isMuted()) {
      ban.unmute();
      gu.unmute();
    } else {
      ban.mute();
      gu.mute();
    }
  }
}

void mouseDragged() {
  if ((mouseX > voiceX+sourceW+ssd+sliderW/2-volButtonW/2) && (mouseX < voiceX+sourceW+ssd+sliderW/2+volButtonW/2)
      && (mouseY > voiceVolY-volButtonH/2) && (mouseY < voiceVolY+volButtonH/2)) {
    if ((mouseY > voiceY) && (mouseY < voiceY+sourceH)) {
      voiceVol = map(mouseY, voiceY, voiceY+sourceH, volMax, volMin);
    }
  } else if ((mouseX > accX+sourceW+ssd+sliderW/2-volButtonW/2) && (mouseX < accX+sourceW+ssd+sliderW/2+volButtonW/2)
      && (mouseY > accVolY-volButtonH/2) && (mouseY < accVolY+volButtonH/2)) {
    if ((mouseY > accY) && (mouseY < accY+sourceH)) {
      accVol = map(mouseY, accY, accY+sourceH, volMax, volMin);
    }
  }
}
