import os
from SCons.Script import (AlwaysBuild, Builder, Environment,
                          Default, Split, GetOption)

# -- Nombre del fichero a ensamblar
NAME = 'simplez'
DEPS_str = 'src/simplez.v src/genram.v src/dividerp1.v src/uart_tx.v \
            src/baudgen_tx.v src/uart_rx.v src/baudgen_rx.v'
DEPS = Split(DEPS_str)
PCF = 'src/' + NAME + '.pcf'

print("DEPS: {}".format(DEPS))

# -- Constructor para sintetizar
synth = Builder(action='yosys -p \"synth_ice40 -blif $TARGET\" {}'.format(DEPS_str),
                suffix='.blif',
                src_suffix='.v')

pnr = Builder(action='arachne-pnr -d 1k -o $TARGET -p {} $SOURCE'.format(PCF),
              suffix='.asc',
              src_suffix='.blif')

bitstream = Builder(action='icepack $SOURCE $TARGET',
                    suffix='.bin',
                    src_suffix='.asc')

# -- Construccion del informe de tiempos
time_rpt = Builder(action='icetime -d hx1k -mtr $TARGET $SOURCE',
                   suffix='.rpt',
                   src_suffix='.asc')

# -- Construir el entorno
env = Environment(BUILDERS={'Synth': synth, 'PnR': pnr,
                            'Bin': bitstream, 'Time': time_rpt},
                  ENV=os.environ)

# -- Sintesis complesta: de verilog a bitstream
blif = env.Synth(NAME, [DEPS, 'prog.list'])
asc = env.PnR([blif, PCF])
Default(env.Bin([asc, 'prog.list']))

# -- Objetivo time para calcular el tiempo
rpt = env.Time(asc)
t = env.Alias('time', rpt)

# ----------- Entorno para simulacion

# -- Constructor para generar simulacion: icarus Verilog
iverilog = Builder(action='iverilog $SOURCES -o $TARGET',
                   suffix='.out',
                   src_suffix='.v')

vcd = Builder(action='./$SOURCE', suffix='.vcd', src_suffix='.out')

# -- Create the simulation environment. All the environment variables are
# included (if not, there is an error executing gtkwave)
simenv = Environment(BUILDERS={'IVerilog': iverilog, 'VCD': vcd},
                     ENV=os.environ)

TB = 'src/' + NAME + '_tb'
out = simenv.IVerilog(NAME+'_tb', Split(DEPS_str+' '+TB+'.v'))
vcd_file = simenv.VCD(out)


gtkwave = simenv.Alias('sim', vcd_file,
                       'gtkwave simulation.vcd src/simulation.gtkw'+' &')
AlwaysBuild(gtkwave)

# -- These is for cleaning the files generated using the alias targets
if GetOption('clean'):
    env.Default(t)
    env.Default(gtkwave)
