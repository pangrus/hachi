Engine_Hachi : CroneEngine {

// Variables
  var <synth;
  var kick_tone = 60;
  var kick_decay = 25;
  var kick_level = 1;
  var ch_decay = 1.5;
  var ch_tone = 500;
  var ch_level = 0.9;
  var oh_decay = 1.5;
  var oh_tone = 400;
  var oh_level = 0.9;
  var snare_tone = 300;
  var snare_snappy = 1.5;
  var snare_level = 0.7;
  var clap_level = 0.4;
  var cowbell_level = 0.3;
  var claves_level = 0.2;


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
	    arg kick_trigger, kick_decay, kick_level, kick_tone;
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
	    sig = Limiter.ar(sig, 0.5) * kick_level;
	    sig = Pan2.ar(sig, 0);
      Out.ar(0, sig);
}).add;

SynthDef.new("ch", {
	arg ch_trigger, ch_tone, ch_decay , ch_level, pan=0;
	var sig, sighi,siglow, sum, env, osc1, osc2, osc3, osc4, osc5, osc6;
	env = EnvGen.kr(Env.perc(0.005, ch_decay, 1, -30),doneAction:3);
	osc1 = LFPulse.ar(ch_tone + 3.52);
	osc2 = LFPulse.ar(ch_tone + 166.31);
	osc3 = LFPulse.ar(ch_tone + 101.77);
	osc4 = LFPulse.ar(ch_tone + 318.19);
	osc5 = LFPulse.ar(ch_tone + 611.16);
	osc6 = LFPulse.ar(ch_tone + 338.75);
	sighi = (osc1 + osc2 + osc3 + osc4 + osc5 + osc6);
    siglow = (osc1 + osc2 + osc3 + osc4 + osc5 + osc6);
    sighi = BPF.ar(sighi, 8900, 1);
    sighi = HPF.ar(sighi, 9000);
    siglow = BBandPass.ar(siglow, 8900, 0.8);
    siglow = BHiPass.ar(siglow, 9000, 0.3);
    sig = BPeakEQ.ar((siglow+sighi), 9700, 0.8, 0.7);
    sig = sig * env * ch_level;
    sig = Pan2.ar(sig, pan);
    Out.ar(0, sig);
}).add;


SynthDef.new("oh", {
	arg oh_trigger, oh_tone, oh_decay, oh_level, pan=0;
	var sig, siga, sigb, env1, env2, osc1, osc2, osc3, osc4, osc5, osc6, sum;
	env1 = EnvGen.kr(Env.perc(0.1, oh_decay, curve:-3), doneAction:2);
	env2 = EnvGen.kr(Env.new([0, 1, 0], [0, oh_decay*5], curve:-150), doneAction:0);
	osc1 = LFPulse.ar(oh_tone + 3.52);
	osc2 = LFPulse.ar(oh_tone + 166.31);
	osc3 = LFPulse.ar(oh_tone + 101.77);
	osc4 = LFPulse.ar(oh_tone + 318.19);
	osc5 = LFPulse.ar(oh_tone + 611.16);
	osc6 = LFPulse.ar(oh_tone + 338.75);
	sig = osc1 + osc2 + osc3 + osc4 + osc5 + osc6;
	sig = BLowShelf.ar(sig, 990, 2, -3);
	sig = BPF.ar(sig, 7700);
	sig = BPeakEQ.ar(sig, 7200, 0.5, 5);
	sig = BHiPass4.ar(sig, 8100, 0.7);
	sig = BHiShelf.ar(sig, 9400, 1, 5);
	siga = sig * env1 * 0.6;
	sigb = sig * env2;
	sum = siga + sigb;
	sum = LPF.ar(sum, 4000);
	sum = Pan2.ar(sum, 0);
	sum = sum * oh_level * 2;
	Out.ar(0, sum);
}).add;

SynthDef.new("snare", {
	arg snare_trigger, snare_level, snare_tone, tone2=189, snare_snappy;
	var noiseEnv, atkEnv, sig, noise, osc1, osc2, sum;
	noiseEnv = EnvGen.kr(Env.perc(0.001, 3.2, 1, -115), doneAction:2);
	atkEnv = EnvGen.kr(Env.perc(0.001, 0.8,curve:-95), doneAction:2);
	noise = WhiteNoise.ar;
	noise = HPF.ar(noise, 1800);
	noise = LPF.ar(noise, 8850);
	noise = noise * noiseEnv * snare_snappy;
	osc1 = SinOsc.ar(tone2, pi/2) * 0.6;
	osc2 = SinOsc.ar(snare_tone, pi/2) * 0.7;
	sum = (osc1+osc2) * atkEnv * snare_level * 2;
	sig = Pan2.ar((noise + sum) * snare_level * 2.5, 0);
	sig = HPF.ar(sig, 340);
	Out.ar(0, sig);
}).add;

SynthDef.new("clap", {
	arg clap_trigger, clap_level, gate=0;
	var atkenv, atk, decay, sum, denv;
	atkenv = EnvGen.kr(Env.new([0.5,1,0],[0, 0.3], -160), doneAction:2);
	denv = EnvGen.kr(Env.dadsr(0.016, 0, 6, 0, 1, 1, curve:-157), doneAction:2);
	atk = WhiteNoise.ar * atkenv * 2;
	decay = WhiteNoise.ar * denv;
	sum = atk + decay * clap_level;
	sum = HPF.ar(sum, 500);
	sum = BPF.ar(sum, 1062, 0.5);
	Out.ar(0, Pan2.ar(sum * 1.5, 0));
}).add;

SynthDef.new("cowbell", {
	arg cowbell_trigger, cowbell_level;
	var sig, pul1, pul2, env, atk, atkenv, datk;
	atkenv = EnvGen.kr(Env.perc(0, 1, 0.1, -215),doneAction:2);
	env = EnvGen.kr(Env.perc(0.01, 9.5, 0.7, -90),doneAction:2);
	pul1 = LFPulse.ar(811.16);
	pul2 = LFPulse.ar(538.75);
	atk = (pul1 + pul2) * atkenv * 6;
	datk = (pul1 + pul2) * env;
	sig = (atk + datk) * cowbell_level;
	sig = HPF.ar(sig, 250);
	sig = LPF.ar(sig, 3500);
	sig = Pan2.ar(sig, 0);
	Out.ar(0, sig);
}).add;

SynthDef.new("claves", {
	arg claves_trigger, claves_level;
	var  env, sig;
	env = EnvGen.kr(Env.new([1, 1, 0], [0, 0.1], -20), doneAction:2);
	sig = SinOsc.ar(2500, pi/2) * env * claves_level;
	sig = Pan2.ar(sig, 0);
	Out.ar(0, sig);
}).add;


// This is how you add "commands", how the lua interpreter controls the engine.

		this.addCommand("kick_trigger", "f", {
		  arg msg;
		  var val = msg[1];
		  Synth("kick", [\out, context.out_b, \kick_trigger,val,\kick_decay,kick_decay,\kick_tone,kick_tone,\kick_level,kick_level], target:pg);
		});

   this.addCommand("kick_tone", "f", {arg msg;
      kick_tone = msg[1];
    });

   this.addCommand("kick_decay", "f", {arg msg;
      kick_decay = msg[1];
    });

    this.addCommand("kick_level", "f", {arg msg;
      kick_level = msg[1];
    });

    this.addCommand("ch_trigger", "f", {
		  arg msg;
		  var val = msg[1];
		  Synth("ch", [\out, context.out_b, \ch_trigger,val,\ch_decay,ch_decay,\ch_tone,ch_tone,\ch_level,ch_level], target:pg);
		});

    this.addCommand("ch_tone", "f", {arg msg;
      ch_tone = msg[1];
    });

    this.addCommand("ch_decay", "f", {arg msg;
      ch_decay = msg[1];
    });

    this.addCommand("ch_level", "f", {arg msg;
      ch_level = msg[1];
    });

  this.addCommand("oh_trigger", "f", {
		  arg msg;
		  var val = msg[1];
		  Synth("oh", [\out, context.out_b, \oh_trigger,val,\oh_decay,oh_decay,\oh_tone,oh_tone,\oh_level,oh_level], target:pg);
		});

  this.addCommand("oh_tone", "f", {arg msg;
      oh_tone = msg[1];
    });

    this.addCommand("oh_decay", "f", {arg msg;
      oh_decay = msg[1];
    });

    this.addCommand("oh_level", "f", {arg msg;
      oh_level = msg[1];
    });

		this.addCommand("snare_trigger", "f", {
		  arg msg;
		  var val = msg[1];
		  Synth("snare", [\out, context.out_b, \snare_trigger,val,\snare_tone,snare_tone,\snare_snappy,snare_snappy,\snare_level,snare_level], target:pg);
		});

    this.addCommand("snare_tone", "f", {arg msg;
      snare_tone = msg[1];
    });

    this.addCommand("snare_snappy", "f", {arg msg;
      snare_snappy = msg[1];
    });

    this.addCommand("snare_level", "f", {arg msg;
      snare_level = msg[1];
    });

		this.addCommand("clap_trigger", "f", {
		  arg msg;
		  var val = msg[1];
		  Synth("clap", [\out, context.out_b, \clap_trigger,val,\clap_level,clap_level], target:pg);
		});
		
		this.addCommand("clap_level", "f", {arg msg;
      clap_level = msg[1];
    });
    
		this.addCommand("claves_trigger", "f", {
		  arg msg;
		  var val = msg[1];
		  Synth("claves", [\out, context.out_b, \claves_trigger,val,\claves_level,claves_level], target:pg);
		});
    
    this.addCommand("claves_level", "f", {arg msg;
      claves_level = msg[1];
    });

		this.addCommand("cowbell_trigger", "f", {
		  arg msg;
		  var val = msg[1];
		  Synth("cowbell", [\out, context.out_b, \cowbell_trigger,val,\cowbell_level,cowbell_level], target:pg);
		});
 
    this.addCommand("cowbell_level", "f", {arg msg;
      cowbell_level = msg[1];
    });

  }

  // Define a function that is called when the synth is shut down
  free {
    synth.free;
  }
}

