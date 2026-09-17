// Ambient-only cycle. All layers use the environment clock, including pause.
float sanctuary_age(float t){
 float cycle=floor(t/26.0);
 float stagger=fract(sin(cycle*12.9898+4.7)*43758.5453)*2.0;
 return mod(t,26.0)-10.0-stagger;
}
float sanctuary_open(float t){float a=sanctuary_age(t);return smoothstep(0.,1.8,a)*(1.-smoothstep(5.,7.5,a));}
float sanctuary_belch(float t){float a=sanctuary_age(t);return smoothstep(1.5,2.3,a)*(1.-smoothstep(4.1,5.4,a));}
float sanctuary_afterglow(float t){float a=sanctuary_age(t);return smoothstep(2.,3.,a)*(1.-smoothstep(6.,9.,a));}
