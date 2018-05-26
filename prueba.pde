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
String titleFile = "sections/aria-title.csv";
Table titleTable;
String title;
String banshiFile = "sections/aria-banshi.csv";
Table banshiTable;
String[] banshi;
int[] banshiStart;
int[] banshiEnd;
int[] bIndex; // banshi index
int banshiIndex;
String linesFile = "sections/aria-line.csv";
Table linesTable;
String[] lines;
int[] linesStart;
int[] linesEnd;
int[] lIndex; // lines index
String tempoFile = "aria_tempocurve.csv";
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
String voiceFile = "voice.mp3";
String accFile = "acc.mp3";
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
int latency = 500;

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
  banshi = new String[linesTable.getRowCount()];
  banshiStart = new int[linesTable.getRowCount()];
  for (int i = 0; i < banshiStart.length; i++) banshiStart[i] = -1;
  banshiEnd = new int[linesTable.getRowCount()];
  for (int i = 0; i < banshiEnd.length; i++) banshiEnd[i] = -1;
  banshiIndex = 0;
  for (int i = 0; i < linesStart.length; i++) {
    if (banshiIndex < banshiTable.getRowCount()) {
      int bStart = int(banshiTable.getFloat(banshiIndex, 1) * 1000);
      if (linesStart[i] >= bStart) {
        banshi[i] = banshiTable.getString(banshiIndex, 0);
        banshiStart[i] = bStart;
        banshiEnd[i] = int(banshiTable.getFloat(banshiIndex, 2) * 1000);
        banshiIndex += 1;
      }
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
    String b = str(tempoData.getFloat(i, 2)); // converts the beat value into string
    beat[i+1] = int(b.charAt(b.length()-1))-48; 
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
  gu = minim.loadSample(guFile);
  gu.setGain(-5);
  
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
      y = map(tempoMin, tempoMin, tempoMax, height-tempoBoxX, height-tempoBoxH-tempoBoxX)-curveWeight;
    } else {
      y = map(tempoValue[i], tempoMin, tempoMax, height-tempoBoxX, height-tempoBoxH-tempoBoxX);
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
  for (int i = 0; i < banshiStart.length; i++) {
    if (banshiStart[i] > -1) bIndex[banshiStart[i]] = i+1;
  }
  for (int i = 0; i < banshiEnd.length; i++) {
    if (banshiEnd[i] > -1) bIndex[banshiEnd[i]] = i+1;
  }  
  int b = 0;
  boolean bWrite = false;
  for (int i = 0; i < bIndex.length; i++) {
    if (bIndex[i] == 0) {
      if (bWrite) {
        bIndex[i] = b;
      } else {
        bIndex[i] = -1;
      }
    } else if (bIndex[i] != 0) {
      if (bWrite) {
        bWrite = false;
      } else {
        b = bIndex[i];
        bWrite = true;
      }
    }
  }
  
  // Lines index
  lIndex = new int[voicePlayer.length()];
  for (int i = 0; i < linesStart.length; i++) {
    lIndex[linesStart[i]] = i+1;
  }
  for (int i = 0; i < linesEnd.length; i++) {
    lIndex[linesEnd[i]] = i+1;
  }  
  int l = 0;
  boolean lWrite = false;
  for (int i = 0; i < lIndex.length; i++) {
    if (lIndex[i] == 0) {
      if (lWrite) {
        lIndex[i] = l;
      } else {
        lIndex[i] = -1;
      }
    } else if (lIndex[i] != 0) {
      if (lWrite) {
        lWrite = false;
      } else {
        l = lIndex[i];
        lWrite = true;
      }
    }
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
  noStroke();
  fill(206, 167, 123);
  rect(lyricsBoxX, lyricsBoxY, width-lyricsBoxX-tempoBoxX, height-lyricsBoxH);
    
  // Tempo curve box background
  noStroke();
  fill(206, 167, 123);
  rect(tempoBoxX, height-tempoBoxX-tempoBoxH, width-(2*tempoBoxX), tempoBoxH);
  
  // Tempo marker
  int tempoInstant = voicePlayer.position();
  String tempoMark;
  tempoMark = nf(tempoValue[index[tempoInstant]], 3, 1);
  textFont(enFont);
  fill(0);
  textSize(tms);
  text(tempoMark+" bpm", tempoBoxX, height-tmY, tms*5, tms+4);
  
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
  
  // Lines boxes
  int lineX = lyricsBoxX+lineAdjust;
  noStroke();
  for (int i = 0; i < linesStart.length; i++) {
    float boxX = map(linesStart[i], 0, voicePlayer.length(), tempoBoxX, width-tempoBoxX);
    float boxW = map(linesEnd[i], 0, voicePlayer.length(), tempoBoxX, width-tempoBoxX) - boxX;
    if (lIndex[tempoInstant] == i+1) {
      fill(255, 128, 0, 150);
      float lineBoxX = lyricsBoxX+lineSize*8+lineAdjust;
      float lineBoxY = lyricsBoxY+lineShift*(i+1)-lineSize-lineAdjust/3;
      rect(lineBoxX, lineBoxY, width-lineBoxX-tempoBoxX, lineSize+lineAdjust);
    } else {
      fill(150, 150);
    }
    rect(boxX, height-tempoBoxX-tempoBoxH, boxW, tempoBoxH);
  }
  
  // Banshi boxes
  int bbYi = 0; // banshi box Y index
  int bbHi; // banshi box height index
  int li = bIndex[tempoInstant]-1; // local index
  for (int i = 1; i < banshiStart.length; i++) {
    if (banshiStart[i] != -1) {
      bbHi = i-bbYi;
      if ((li >= 0) && (tempoInstant >= banshiStart[li]) && (tempoInstant <= banshiEnd[li])) {
        fill(255, 128, 0, 150);
      } else {
        noFill();
      }
      float banshiBoxY = lyricsBoxY+lineShift*(bbYi+1)-lineSize-lineAdjust/3;
      rect(lyricsBoxX, banshiBoxY, lineSize*8+lineAdjust, (lineSize+lineAdjust)*bbHi);
      bbYi = i;
      }
    if (i == banshiStart.length-1) {
      bbHi = i-bbYi+1;
      if ((li >= 0) && (tempoInstant >= banshiStart[li]) && (tempoInstant <= banshiEnd[li])) {
        fill(255, 128, 0, 150);
      } else {
        noFill();
      }
      float banshiBoxY = lyricsBoxY+lineShift*(bbYi+1)-lineSize-lineAdjust/3;
      rect(lyricsBoxX, banshiBoxY, lineSize*8+lineAdjust, (lineSize+lineAdjust)*bbHi);
    }
  }
  
  // Banshi
  textFont(zhFont);
  fill(0);
  textSize(lineSize);
  for (int i = 0; i < banshi.length; i++) {
    if (banshi[i] != null) {
      text(banshi[i], lineX, lyricsBoxY+lineShift*(i+1));
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
  for (int i = 0; i < lines.length; i++) {
    text(lines[i], lineX+lineSize*8+lineAdjust, lyricsBoxY+lineShift*(i+1));
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
  rect(lyricsBoxX, lyricsBoxY, width-lyricsBoxX-tempoBoxX, height-lyricsBoxH);
  
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
