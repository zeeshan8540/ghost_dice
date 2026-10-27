// Web Audio API funny sound synthesizer for browser environment.
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

class SoundEffectService {
  static void playFunnyKillSound() {
    try {
      js.context.callMethod('eval', [r'''
        (function() {
          try {
            var AudioCtx = window.AudioContext || window.webkitAudioContext;
            if (!AudioCtx) return;
            var ctx = window._ghostDiceAudioCtx || new AudioCtx();
            window._ghostDiceAudioCtx = ctx;
            if (ctx.state === 'suspended') { ctx.resume(); }

            var now = ctx.currentTime;

            // 1. Comical descending slide whistle ("wheeeeeee-")
            var osc1 = ctx.createOscillator();
            var gain1 = ctx.createGain();
            osc1.type = 'sine';
            osc1.frequency.setValueAtTime(920, now);
            osc1.frequency.exponentialRampToValueAtTime(140, now + 0.38);

            gain1.gain.setValueAtTime(0.32, now);
            gain1.gain.exponentialRampToValueAtTime(0.01, now + 0.38);

            osc1.connect(gain1);
            gain1.connect(ctx.destination);
            osc1.start(now);
            osc1.stop(now + 0.39);

            // 2. Comic Spring Boing / Bonk ("-BOING!")
            var osc2 = ctx.createOscillator();
            var gain2 = ctx.createGain();
            osc2.type = 'triangle';
            osc2.frequency.setValueAtTime(130, now + 0.36);
            osc2.frequency.exponentialRampToValueAtTime(460, now + 0.46);
            osc2.frequency.exponentialRampToValueAtTime(110, now + 0.72);

            gain2.gain.setValueAtTime(0.38, now + 0.36);
            gain2.gain.exponentialRampToValueAtTime(0.001, now + 0.72);

            osc2.connect(gain2);
            gain2.connect(ctx.destination);
            osc2.start(now + 0.36);
            osc2.stop(now + 0.73);

            // 3. Comic vibrato warble
            var osc3 = ctx.createOscillator();
            var gain3 = ctx.createGain();
            osc3.type = 'square';
            osc3.frequency.setValueAtTime(280, now + 0.44);
            osc3.frequency.exponentialRampToValueAtTime(80, now + 0.68);

            gain3.gain.setValueAtTime(0.08, now + 0.44);
            gain3.gain.exponentialRampToValueAtTime(0.001, now + 0.68);

            osc3.connect(gain3);
            gain3.connect(ctx.destination);
            osc3.start(now + 0.44);
            osc3.stop(now + 0.69);
          } catch(e) {}
        })();
      ''']);
    } catch (_) {}
  }

  static void playHopSound() {
    try {
      js.context.callMethod('eval', [r'''
        (function() {
          try {
            var AudioCtx = window.AudioContext || window.webkitAudioContext;
            if (!AudioCtx) return;
            var ctx = window._ghostDiceAudioCtx || new AudioCtx();
            window._ghostDiceAudioCtx = ctx;
            if (ctx.state === 'suspended') { ctx.resume(); }

            var now = ctx.currentTime;
            var osc = ctx.createOscillator();
            var gain = ctx.createGain();

            // Tactile piece touchdown clack
            osc.type = 'triangle';
            osc.frequency.setValueAtTime(420, now);
            osc.frequency.exponentialRampToValueAtTime(160, now + 0.045);

            gain.gain.setValueAtTime(0.20, now);
            gain.gain.exponentialRampToValueAtTime(0.001, now + 0.05);

            osc.connect(gain);
            gain.connect(ctx.destination);
            osc.start(now);
            osc.stop(now + 0.055);
          } catch(e) {}
        })();
      ''']);
    } catch (_) {}
  }

  static void playDiceRollSound() {
    try {
      js.context.callMethod('eval', [r'''
        (function() {
          try {
            var AudioCtx = window.AudioContext || window.webkitAudioContext;
            if (!AudioCtx) return;
            var ctx = window._ghostDiceAudioCtx || new AudioCtx();
            window._ghostDiceAudioCtx = ctx;
            if (ctx.state === 'suspended') { ctx.resume(); }

            var now = ctx.currentTime;
            for (var i = 0; i < 4; i++) {
              var t = now + i * 0.08;
              var osc = ctx.createOscillator();
              var gain = ctx.createGain();
              osc.type = 'triangle';
              osc.frequency.setValueAtTime(320 + i * 40, t);
              gain.gain.setValueAtTime(0.15, t);
              gain.gain.exponentialRampToValueAtTime(0.001, t + 0.04);
              osc.connect(gain);
              gain.connect(ctx.destination);
              osc.start(t);
              osc.stop(t + 0.045);
            }
          } catch(e) {}
        })();
      ''']);
    } catch (_) {}
  }
}
