Engine_Hachi : CroneEngine {


// Variables
  var <synth;
  var kick_amp = 0.8;
  var kick_tone = 56;
  var kick_decay = 20;
  var hh_decay = 0.5;
  var hh_tone = 200;
  var snare_tone = 340;
  var snappy = 0.3;


// This is your constructor. the 'context' arg is a CroneAudioContext.
  *new { 
  arg context, doneCallback;
  ^super.new(context, doneCallback);
  }


// this is called when the engine is actually loaded by a script.
  alloc {

		var pg = ParGroup.tail(context.xg);

// SynthDefs

SynthDef("kick", {
	    arg kick_trigger, kick_decay, kick_amp, kick_tone;
	    var fenv, env, trienv, sig, sub, punch, pfenv;
	    env = EnvGen.kr(Env.new([0.11, 1, 0], [0, kick_decay], -225),doneAction:3);
	    trienv = EnvGen.kr(Env.new([0.11, 0.6, 0], [0, kick_decay], -230),doneAction:3);
	    fenv = Env([kick_tone*7, kick_tone*1.35, kick_tone], [0.05, 0.6], -14,doneAction:3).kr;
	    pfenv = Env([kick_tone*7, kick_tone*1.35, kick_tone], [0.03, 0.6], -10,doneAction:3).kr;
	    sig = SinOsc.ar(fenv, pi/2) * env;
	    sub = LFTri.ar(fenv, pi/2) * trienv * 0.05;
	    punch = SinOsc.ar(pfenv, pi/2) * env * 2;
	    punch = HPF.ar(punch, kick_tone);
	    sig = (sig + sub + punch) * 2.5;
	    sig = Limiter.ar(sig, 0.5) * kick_amp;
	    sig = Pan2.ar(sig, 0);
      Out.ar(0, sig);
}).add;

SynthDef.new("hhclosed", {
	arg hhclosed_trigger, hh_tone = 200, hh_decay = 0.5, amp = 0.8, pan=0;
	var sig, sighi,siglow, sum, env, osc1, osc2, osc3, osc4, osc5, osc6;
	env = EnvGen.kr(Env.perc(0.005, hh_decay, 1, -30),doneAction:3);
	osc1 = LFPulse.ar(hh_tone + 3.52);
	osc2 = LFPulse.ar(hh_tone + 166.31);
	osc3 = LFPulse.ar(hh_tone + 101.77);
	osc4 = LFPulse.ar(hh_tone + 318.19);
	osc5 = LFPulse.ar(hh_tone + 611.16);
	osc6 = LFPulse.ar(hh_tone + 338.75);
	sighi = (osc1 + osc2 + osc3 + osc4 + osc5 + osc6);
    siglow = (osc1 + osc2 + osc3 + osc4 + osc5 + osc6);
    sighi = BPF.ar(sighi, 8900, 1);
    sighi = HPF.ar(sighi, 9000);
    siglow = BBandPass.ar(siglow, 8900, 0.8);
    siglow = BHiPass.ar(siglow, 9000, 0.3);
    sig = BPeakEQ.ar((siglow+sighi), 9700, 0.8, 0.7);
    sig = sig * env * amp;
    sig = Pan2.ar(sig, pan);
    Out.ar(0, sig);
}).add;

SynthDef.new("snare", {
	arg snare_trigger, amp=0.3, snare_tone, tone2=189, snappy, gate=0, amp2=0.8;
	var noiseEnv, atkEnv, sig, noise, osc1, osc2, sum;
	noiseEnv = EnvGen.kr(Env.perc(0.001, 3.2, 1, -115), doneAction:2);
	atkEnv = EnvGen.kr(Env.perc(0.001, 0.8,curve:-95), doneAction:2);
	noise = WhiteNoise.ar;
	noise = HPF.ar(noise, 1800);
	noise = LPF.ar(noise, 8850);
	noise = noise * noiseEnv * snappy;
	osc1 = SinOsc.ar(tone2, pi/2) * 0.6;
	osc2 = SinOsc.ar(snare_tone, pi/2) * 0.7;
	sum = (osc1+osc2) * atkEnv * amp2;
	sig = Pan2.ar((noise + sum) * amp * 2.5, 0);
	sig = HPF.ar(sig, 340);
	Out.ar(0, sig);
}).add;

SynthDef.new("clap", {
	arg clap_trigger, amp=1, gate=0;
	var atkenv, atk, decay, sum, denv;
	atkenv = EnvGen.kr(Env.new([0.5,1,0],[0, 0.3], -160), doneAction:2);
	denv = EnvGen.kr(Env.dadsr(0.016, 0, 6, 0, 1, 1, curve:-157), doneAction:2);
	atk = WhiteNoise.ar * atkenv * 2;
	decay = WhiteNoise.ar * denv;
	sum = atk + decay * amp;
	sum = HPF.ar(sum, 500);
	sum = BPF.ar(sum, 1062, 0.5);
	Out.ar(0, Pan2.ar(sum * 1.5, 0));
}).add;

SynthDef.new("cowbell", {
	arg cowbell_trigger, amp=0.1;
	var sig, pul1, pul2, env, atk, atkenv, datk;
	atkenv = EnvGen.kr(Env.perc(0, 1, 0.1, -215),doneAction:2);
	env = EnvGen.kr(Env.perc(0.01, 9.5, 0.7, -90),doneAction:2);
	pul1 = LFPulse.ar(811.16);
	pul2 = LFPulse.ar(538.75);
	atk = (pul1 + pul2) * atkenv * 6;
	datk = (pul1 + pul2) * env;
	sig = (atk + datk) * amp;
	sig = HPF.ar(sig, 250);
	sig = LPF.ar(sig, 3500);
	sig = Pan2.ar(sig, 0);
	Out.ar(0, sig);
}).add;

SynthDef.new("claves", {
	arg claves_trigger, amp=0.7;
	var  env, sig;
	env = EnvGen.kr(Env.new([1, 1, 0], [0, 0.1], -20), doneAction:2);
	sig = SinOsc.ar(2500, pi/2) * env * amp;
	sig = Pan2.ar(sig, 0);
	Out.ar(0, sig);
}).add;


// This is how you add "commands", how the lua interpreter controls the engine.

		this.addCommand("kick_trigger", "f", {
		  arg msg;
		  var val = msg[1];
		  Synth("kick", [\out, context.out_b, \kick_trigger,val,\kick_decay,kick_decay,\kick_tone,kick_tone,\kick_amp,kick_amp], target:pg);
		});

   this.addCommand("kick_tone", "f", {arg msg;
      kick_tone = msg[1];
    });

   this.addCommand("kick_decay", "f", {arg msg;
      kick_decay = msg[1];
    });

    this.addCommand("kick_amp", "f", {arg msg;
      kick_amp = msg[1];
    });

    this.addCommand("hhclosed_trigger", "f", {
		  arg msg;
		  var val = msg[1];
		  Synth("hhclosed", [\out, context.out_b, \hhclosed_trigger,val,\hh_decay,hh_decay,\hh_tone,hh_tone], target:pg);
		});

    this.addCommand("hh_tone", "f", {arg msg;
      hh_tone = msg[1];
    });

    this.addCommand("hh_decay", "f", {arg msg;
      hh_decay = msg[1];
    });

		this.addCommand("snare_trigger", "f", {
		  arg msg;
		  var val = msg[1];
		  Synth("snare", [\out, context.out_b, \snare_trigger,val,\snare_tone,snare_tone,\snappy,snappy], target:pg);
		});

    this.addCommand("snare_tone", "f", {arg msg;
      snare_tone = msg[1];
    });

    this.addCommand("snappy", "f", {arg msg;
      snappy = msg[1];
    });


		this.addCommand("cowbell_trigger", "f", {
		  arg msg;
		  var val = msg[1];
		  Synth("cowbell", [\out, context.out_b, \cowbell_trigger,val], target:pg);
		});
		
		
		this.addCommand("clap_trigger", "f", {
		  arg msg;
		  var val = msg[1];
		  Synth("clap", [\out, context.out_b, \clap_trigger,val], target:pg);
		});
		
		this.addCommand("claves_trigger", "f", {
		  arg msg;
		  var val = msg[1];
		  Synth("claves", [\out, context.out_b, \claves_trigger,val], target:pg);
		});
  }

  // Define a function that is called when the synth is shut down
  free {
    synth.free;
  }
}

