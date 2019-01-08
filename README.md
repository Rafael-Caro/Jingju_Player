# Jingju Player
_**An enhanced player for the understanding of jingju arias**_

Understanding the elements of jingju music is an important requirement for its appreciation and enjoyment. This tool is designed with the aim of guiding the listener to special use of musical metre in jingju through the concept of _banshi_ and its relationship with the content of the lyrics. It also allows to explore the relationship between the singing voice and the instrumental accompaniment of the jinghu.

## Functionalities
![Screenshot of the Jingju Player](https://github.com/Rafael-Caro/Jingju_Player/blob/master/data/screenshot.png)

This preliminary version of the Jingju Player demonstrates its functionalities with the aria “昔日有个三大贤”——《珠帘寨》（李克用）"In ancient times where Three Great Sages," from _The Zhulian Stockade_ (Li Keyong).

The **lyrics window** (1) offers, in the second column, the lyrics of the aria both in its original Chinese and in its English translation. The first column shows a label with _shengqiang_ and _banshi_. The line in parallel to this label and the following ones are sung in the _shengqiang_ and _banshi_ indicated by that label. To see the lyrics that do not fit in the lyrics window, the scroll down button at the bottom of the lyrics window can be clicked.

The **navigation window** (2) shows a general structure of the aria. The shadowed areas correspond to each of the lyrics lines and their width correspond to the required time for singing them. The _shengqiang banshi_ labels are also added on the top of the window. The superimposed gray line is a tempo curve, that indicates the evolution of the tempo throughout the aria. When a free metred _banshi_ is used, the line shows no value.

When the aria is played using the playback buttons (3), a cursor in the navigation window shows the current point of the aria being played. Both the current _shengqiang banshi_ label and lyrics line are highlighted in both the lyrics window and the navigation window.

The **tempo box** (4) shows the exact tempo value in bpm of the current point. If a free metred _banshi_ is being played, the box shows the message "Scattered."

Next to the tempo box, the **metre marker** (5) indicates the metre by blinking red for each downbeat and green for each upbeat. Besides, by deafult a ban clappers sound is played for each downbeat and a danpigu drum sound is played for each upbeat. If the the metre marker is clicked, the ban and danpigu sounds are muted.

The **source buttons** allows for muting either the singing voice (6) or the accompanying jinghu (7). The sliders next to them adjust the volume of each of the sources.
