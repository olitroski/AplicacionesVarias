* ---------------------------------------------------------------------------- *
* ---- Ejemplo para implementar el calculo de trayectorias combinando el ----- *
* ---- splines package del R y el TRAJ del Stata. v1. 09.08.2019 ------------- *
* ---------------------------------------------------------------------------- *
/* La secuencia del proceso es la siguiente (Si no funcionara el Excel en R <¿Mac?>)
1. Tener un Excel con datos en formato wide
2. Leer esos datos y quedarse solo con el id, tiempo y medición
3. Hacer un reshape a long y guardar en formato Stata 12 (saveold)
4. En R cargar los datos y calcular el 'spline basis' con el comando bs
5. En R aplicar data management para exportar el 'spline basis' a formato stata
6. Cargar en Stata, renombrar variables y hacer el reshape de vuelta a wide
7. Calcular trayectorias

Estrategia de análisis
* En R estimar un spline basis con 4 df (1 spline) y llevar a Stata
* En Stata calcular 1, 2, 3, 4, 5 trayectorias, anotar BIC y AIC

* En R estimar un spline basis con 5 df (2 spline) y llevar a Stata
* En Stata calcular 1, 2, 3, 4, 5 trayectorias, anotar BIC y AIC

* En R estimar un spline basis con 6 df (3 spline) y llevar a Stata
* En Stata calcular 1, 2, 3, 4, 5 trayectorias, anotar BIC y AIC
Y así, con unos 5 splines maximo estimo queda bien.
Si se hace así se tendrán 25 BIC
*/

* ---------------------------------------------------------------------------- *
* ---- Traer el Excel a Stata y prepararlo para el R ------------------------- *
* ---- EN CASO DE NO PODER IMPORTAR EXCEL EN R, si no usar directo el R ------ *
* ---------------------------------------------------------------------------- *
* Cargar el espacio de trabajo
cd "escribir acá la ruta a la carpeta de trabajo"

* Importar el Excel
import excel using "OPPOSITN.xlsx", clear first sheet("OPPOSITN")
edit  //Esta es la estructura de datos, no más variables que id, tiempo y medicion

* Guardar los datos en formato Stata 12 para tener los datos en versión WIDE
saveold "OPPOSITN_wide.dta", replace

* Reshape de wide a long
reshape long V0 T0, i(id) j(epoch)

* El tiempo quedó en T0 y la medición en V0. Cambiar nombres
rename (V0 T0) (data time)

* Guardar formato long para pasar al R
save "OPPOSITN_long.dta", replace



// ########################
// #### Nos vamos al R ####
// ########################


* ---------------------------------------------------------------------------- *
* ---- Traer el Spline Basis que se hizo en R y calcular trayectorias -------- *
* ---------------------------------------------------------------------------- *
* Cargar el archivo que hicimos en R
use "OPPOSITN_longSpline.dta", clear

* Reshape para dejar en wide
reshape wide data time sp_uno sp_dos sp_tre sp_cua, i(id) j(epoch)

* Si vemos las variables están en un orden raro, ordenamos
order id time* data*

* Calculamos 2 trayectorias
traj, var(data*) indep(time*) model(cnorm) min(0) max(10) order(0 0) tcov(sp_uno* sp_dos* sp_tre* sp_cua*)
trajplot

* Calculamos 3 trayectorias
traj, var(data_*) indep(time_*) model(cnorm) min(0) max(10) order(0 0 0) tcov(sp_uno* sp_dos* sp_tre* sp_cua*)
trajplot

// ---------------------------------------------------------------------//
// Y así hasta 5                                                        //
// Ojo que si usamos más splines, vamos a tener más variables en "tcov" //
// ---------------------------------------------------------------------//





