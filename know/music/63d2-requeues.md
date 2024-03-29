## this playlist is not even pre-release
listing and metrics are converging to
a volume two release, more etudes,
more jazz and aesthetic tuning...

documentaries are often slowed doen a little bit to give a contemplative look, lion king 2019 narrative 1:01:05
anthropomorphic look 

{seq},{composer}-{catalog-title}-{record-movement}-{year}-{performer-year}-{label}-{note} 
\_^{youtube-id}-{start-stop-position}-{tempo-pitch-parameters}-{level-compression-parameters}.mp3


When shifting keys, the tonal quality rotates around a circular spectrum of temperament

<pre>
<tt>
C  - clear - doh strong or firm
Cs - broken
D  - pendulum - ray rousing or hopeful
Ef - unsettling, piercing
E  - pierce, penetrating - me steady or calm
F  - regal, balanced - fah desolate or awe-inspiring
Fs - triumphant
G  - spiral - soh, grand or bright
Af - subtle, grounding
A  - listen - lah sad or weeping
Bf - predictable
B  - power - te pericing or sensitive

    ra
C   do (or doh in tonic sol-fa)   Red
    di
    me or ma
D   re   Orange
    ri
E   mi   Yellow
    se
F   fa   Green
    fi
    le or lo
G   sol (or so in tonic sol-fa)   Blue
    si
    te ta
A   la   Indigo, Blue violet
    li
B   ti   Purple, Red violet
</tt>
</pre>


Particularly with 17 century music, somber or melancholy works may have a tempo so slow
that the melody becomes disconnected, these pieces have been accelerated to t=0.92 (total
time is 92% of original), or faster, to add coherence. When the melody or expression becomes
familiar, listening at the originally indicated tempo becomes more intelligible, by today's
standards. This genera of music uses the very slow cadence as a rhetorical devise, immersing
the listener into an unnaturally slow pace, with intention of submitting to the melody, akin
to the immutable hand of God, as it where, moving slowly like the heavens, creating humility
in the listener. This may require carefull listening, deliberate submission, to see the big
picture. Today we expect faster, matter of fact messaging, we don't emotionally submit to a
very slow somber melodic tempo, and miss the message. These works are presented in a faster
tempo to facilitate their appreciation in today's standards.

107,Stan_Getz-Youre_Blase-Cool_^jw0Cg7hCwOc.m4a-ss1035-to1289-t0.9574-p0.0078-c3-F-ln-cps1-v5db.mp3
805,Dave_Brubeck-Georgia_On_My_Mind_^WVLKN-Zp13E.opus-to399.11-t0.920-p0.01-c5-F-ln-cps1-v5db.mp3

Similarly, 
Rondo
Caprice

chords that make notes
<pre>
t=4 ss=3:53:26 to=3:53:29 f2rb2mp3 _^G7sDg8_26N8.opus lower_resonances
t=10 ss=3:54:27.25 to=3:54:28.4  _^G7sDg8_26N8.opus higher_harmonics
t=20 ss=4:57:23 to=4:57:25.5 _^G7sDg8_26N8.opus sustain_induced_bass
t=0.95 ss=5:12:25.5 to=5:12:47 _^G7sDg8_26N8.opus propitious_pattern
</pre>

While the original tempos expected a more    
   hypnotic effect
; to convey . experience tonality conveyance   
   the sadness of tonality we recognize these works are more operated   
   the time of , often the original tries to achieve we miss the the    
   tempo Somber                                                         

  
As discussed, here is my first playlist and intro,
https://github.com/georgalis/pub/blob/master/know/music/5fb3-deja-muse.md
download the 6GB folder, or individual tracks here
https://drive.google.com/drive/folders/1oBl4F1bjyzxxP2iFutOKs4Ms5MvH-xGu?usp=sharing

There are about 1000 tracks in volume two!
https://github.com/georgalis/pub/blob/lufs/know/music/660e-requeues.txt
still (everyday) adjusting content and parameters in the second volume.

When released, there will be a new intro for volume two.

If you are into programming, these are the primary functions for the workflow I described...
</pre>
f2rb2mp3 https://github.com/georgalis/pub/blob/9d9cabd5e58ddfe785b9213c13c00ea207e6f8b5/sub/fn.bash#L220
formfile https://github.com/georgalis/pub/blob/9d9cabd5e58ddfe785b9213c13c00ea207e6f8b5/sub/fn.bash#L400
numlist https://github.com/georgalis/pub/blob/9d9cabd5e58ddfe785b9213c13c00ea207e6f8b5/sub/fn.bash#L713
playff https://github.com/georgalis/pub/blob/9d9cabd5e58ddfe785b9213c13c00ea207e6f8b5/sub/fn.bash#L782
_youtube https://github.com/georgalis/pub/blob/9d9cabd5e58ddfe785b9213c13c00ea207e6f8b5/sub/fn.bash#L178
</pre>

some dependant functions are defined in https://github.com/georgalis/pub/blob/master/skel/.profile

might be tricky to reverse engineer, but I'm happy to help if you want to try the workflow!

This Youtube track has a broken mastering, sounds as if the mic engineer and the recording
engineer and the mastering engineer all had a different plan for the mid/side mic setup.
On the stereo album release, channel b is the side, with digital max noise and the channel a
middle benefits from stereo separation. Invoking the tools below converts left mid right
side mode to left right stereo. A noticeable improvement, a digital peak to zero (or +-1) to
remove more simbalance. The new master as is listenable and sounds pretty good!

<code code=bash>
ss= ; Mo0,Stan_Hunter_Sonny_Fortune_Trip_On_The_Strip-20220321_^Tw6zmXjALm8.info.json.txt
ss= ; export _f=@/_^Tw6zmXjALm8.opus _f1=@/_^Tw6zmXjALm8-ms.wav _a=Stan_Hunter _r=Trip_On_The_Strip-1965
ss= ; ffmpeg -hide_banner -loglevel debug -benchmark -i "$_f" -af "stereotools=mode=ms>lr:level_in=0.91:mlev=0.94:slev=0.0295:softclip=true:phaser=true:delay=-14.96:bmode_in=balance:bmode_out=balance:level_out=1" -f wav "$_f1"
 ss= ; rm -f @/tmp/_^Tw6zmXjALm8*
ss= ; export ss= to= t= p= f= c= F= CF= off= tp= lra= i= cmp= v=
ss= ; export verb=chkwrn cmp=cps1 v=6db

ss=0     to=04:55         f2rb2mp3 $_f1 0a1,${_a}-Trip_On_The_Strip-${_r}
ss=04:55 to=07:29         f2rb2mp3 $_f1 0a2,${_a}-Yesterday-${_r}
ss=07:29 to=11:56         f2rb2mp3 $_f1 0a3,${_a}-Corn_Flakes-${_r}
ss=11:56 to=14:46         f2rb2mp3 $_f1 0a4,${_a}-This_Is_All_I_Ask-${_r}
ss=11:56 to=14:46 t=0.75  f2rb2mp3 $_f1 0a4,${_a}-This_Is_All_I_Ask-${_r}
ss=14:46 to=20:54         f2rb2mp3 $_f1 0b1,${_a}-HFR-${_r}
ss=20:54 to=28:51         f2rb2mp3 $_f1 0b2,${_a}-Invitation-${_r}
ss=20:54 to=28:51 t=0.555 f2rb2mp3 $_f1 0b2,${_a}-Invitation-${_r}
ss=28:51 to=2099          f2rb2mp3 $_f1 0b3,${_a}-Sonnys_Mood-${_r}
ss=28:51 to=2099 t=1.4285 f2rb2mp3 $_f1 0b3,${_a}-Sonnys_Mood-${_r}

0a1,Stan_Hunter-Trip_On_The_Strip-Trip_On_The_Strip-1965_^Tw6zmXjALm8-ms.wav-to295-ln-cps1-v6db.mp3
0a2,Stan_Hunter-Yesterday-Trip_On_The_Strip-1965_^Tw6zmXjALm8-ms.wav-ss295-to449-ln-cps1-v6db.mp3
0a3,Stan_Hunter-Corn_Flakes-Trip_On_The_Strip-1965_^Tw6zmXjALm8-ms.wav-ss449-to716-ln-cps1-v6db.mp3
0a4,Stan_Hunter-This_Is_All_I_Ask-Trip_On_The_Strip-1965_^Tw6zmXjALm8-ms.wav-ss716-to886-ln-cps1-v6db.mp3
0a4,Stan_Hunter-This_Is_All_I_Ask-Trip_On_The_Strip-1965_^Tw6zmXjALm8-ms.wav-ss716-to886-t0.75-c5-ln-cps1-v6db.mp3
0b1,Stan_Hunter-HFR-Trip_On_The_Strip-1965_^Tw6zmXjALm8-ms.wav-ss886-to1254-ln-cps1-v6db.mp3
0b2,Stan_Hunter-Invitation-Trip_On_The_Strip-1965_^Tw6zmXjALm8-ms.wav-ss1254-to1731-ln-cps1-v6db.mp3
0b2,Stan_Hunter-Invitation-Trip_On_The_Strip-1965_^Tw6zmXjALm8-ms.wav-ss1254-to1731-t0.555-c5-ln-cps1-v6db.mp3
0b3,Stan_Hunter-Sonnys_Mood-Trip_On_The_Strip-1965_^Tw6zmXjALm8-ms.wav-ss1731-to2099-ln-cps1-v6db.mp3
0b3,Stan_Hunter-Sonnys_Mood-Trip_On_The_Strip-1965_^Tw6zmXjALm8-ms.wav-ss1731-to2099-t1.4285-c5-ln-cps1-v6db.mp3
</code>


