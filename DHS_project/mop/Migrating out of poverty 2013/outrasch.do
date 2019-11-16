set more off

set scheme sj
set mem 9m

sjlog using outrasch1,replace
use data
raschtest c*, method(cml) mean group(1 2 3 5 8)
sjlog close,replace

sjlog using outrasch2,replace
raschtest c2-c9, method(cml) mean group(1 2 3 4  7)
sjlog close,replace

sjlog using outrasch3,replace
raschtest c2-c4 c6-c9, method(cml) mean group(1 2 3 6)
sjlog close,replace

sjlog using outrasch4,replace
raschtest c2-c4 c7-c9, method(cml) mean group(1 2 3 5) icc information graph /*
  */fitgraph dirsave(graphs) filessave replace
sjlog close,replace


graph use "graphs\iccc7.gph"
graph export "graphs\iccc7.eps",replace
graph use "graphs\graph.gph"
graph export "graphs\graph.eps",replace
graph use "graphs\information.gph"
graph export "graphs\information.eps",replace
graph use "graphs\outfitind.gph"
graph export "graphs\outfitind.eps",replace
graph use "graphs\infitind.gph"
graph export "graphs\infitind.eps",replace
