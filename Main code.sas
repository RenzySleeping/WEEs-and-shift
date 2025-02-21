proc import datafile="D:\Database\UKB\UKB.1.sav" replace out=UKB_1;run;
proc import datafile="D:\Database\UKB\UKB.2.sav" replace out=UKB_2;run;
proc import datafile="D:\Database\UKB\Outcomes\Renamed first occurrence.sav" replace out=raw_firstoccurrence;run;
proc import datafile="D:\Database\UKB\Outcomes\All hospitalization.sav" replace out=raw_all_hospital;run;
proc import datafile="D:\Database\UKB\Outcomes\Primary hospitalization.sav" replace out=raw_main_hospital;run;
proc import datafile="D:\Database\UKB\Outcomes\Cancer registry.sav" replace out=cancerregistry;run;
data raw_UKB;
merge UKB_1 UKB_2 raw_firstoccurrence raw_all_hospital raw_main_hospital cancerregistry;
by n_eid;

if s_22500_0_0>.;*Participated in occupational history interview;

format birthdate date9.;
birthdate=mdy(n_52_0_0,15,n_34_0_0);
age=YRDIF(birthdate,s_53_0_0,'ACTUAL');
if age<55;

if n_6142_0_0=1;*Current employed;

array n_22602[40] n_22602_0_0-n_22602_0_39;*Job began year;
array n_22603[40] n_22603_0_0-n_22603_0_39;*Job ended year;
array n_22617[40] n_22617_0_0-n_22617_0_39;*Job code;
*Work year;
jobcount=0;
array work_year[40] work_year_0-work_year_39;
do i=1 to 40;
   if n_22603[i]=-313 or n_22603[i]>YEAR(s_53_0_0) then n_22603[i]=YEAR(s_53_0_0);
   if n_22602[i]>YEAR(s_53_0_0) or n_22602[i]>n_22603[i] then do;n_22602[i]=.;n_22603[i]=.;n_22617[i]=.;end;
   work_year[i]=n_22603[i]-n_22602[i];if work_year[i]=0 then work_year[i]=0.5;
   if n_22602[i]>. then jobcount+1;
end;drop i;
if jobcount>=1;
if jobcount>=4 then jobcount=4;

*Main job;
MaxDuration=0;
MainJobCode=0;
do i=1 to 40;
   if work_year[i]>0 then do;
      if work_year[i]>MaxDuration then do;
         MaxDuration=work_year[i];
         MainJobCode=n_22617[i];
      end;
   end;
end;drop i MaxDuration;
length MainJob$50;
if int(MainJobCode/1000) in (1,2) then MainJob='Managerial and Professional';
else if int(MainJobCode/1000)=3 then MainJob='Associate Professional and Technical';
else if int(MainJobCode/1000)=4 then MainJob='Administrative and Secretarial';
else if int(MainJobCode/1000) in (5,6,7) then MainJob='Skilled, Service, and Sales';
else if int(MainJobCode/1000) in (8,9) then MainJob='Operative and Elementary';

*Working hour;
array n_22604[40] n_22604_0_0-n_22604_0_39;*Imputed hour;
array n_22605[35] n_22605_0_0-n_22605_0_34;*Exact hour;
do i=1 to 40;
   if n_22604[i]=-3040 then n_22604[i]=35;
   else if n_22604[i]=-2030 then n_22604[i]=25;
   else if n_22604[i]=-1520 then n_22604[i]=17.5;
   else if n_22604[i]=4000 then n_22604[i]=40;
end;drop i;
array raw[35] work_hour0-work_hour34;
do i=1 to 35;
   raw[i]=max(n_22604[i],n_22605[i]);
end;drop i;
work_hour35=n_22604_0_35;work_hour36=n_22604_0_36;work_hour37=n_22604_0_37;work_hour38=n_22604_0_38;work_hour39=n_22604_0_39;
array work_hour[40] work_hour0-work_hour39;
yearhour=0;
do i=1 to 40;
   if work_year[i]>0 and work_hour[i]=. then delete;
   if work_hour[i]>=40 then yearhour=yearhour+work_year[i];
end;drop i;
if yearhour=0 then grade_hour=1;
else if yearhour<20 then grade_hour=2;
else grade_hour=3;

array shift_day[40] shift_day_0-shift_day_39;
array shift_mix[40] shift_mix_0-shift_mix_39;
array shift_night[40] shift_night_0-shift_night_39;
array n_22620[40] n_22620_0_0-n_22620_0_39;*shift status;
array n_22630[40] n_22630_0_0-n_22630_0_39;*day shift;
array n_22631[40] n_22631_0_0-n_22631_0_39;*day shift year;
array n_22640[40] n_22640_0_0-n_22640_0_39;*mixture shift;
array n_22641[40] n_22641_0_0-n_22641_0_39;*mixture shift year;
array n_22643[40] n_22643_0_0-n_22643_0_39;*nights of mixture shift;
array mix_day[40] mix_day_0_0-mix_day_0_39;
array n_22650[40] n_22650_0_0-n_22650_0_39;*night shift;
array n_22651[40] n_22651_0_0-n_22651_0_39;*night shift year;
array n_22653[40] n_22653_0_0-n_22653_0_39;*nights of night shift;
array night_day[40] night_day_0_0-night_day_0_39;

do i=1 to 40;
   if n_22620[i]=1 then do;
      if n_22630[i]=0 and n_22631[i]=-1001 then shift_day[i]=0.5;
      else if n_22630[i]=0 and n_22631[i]>0 then shift_day[i]=n_22631[i];
	  else if n_22630[i]=1 then shift_day[i]=work_year[i];
	  else if n_22630[i]=9 then shift_day[i]=0;

      if n_22640[i]=0 and n_22641[i]=-1001 then shift_mix[i]=0.5;
	  else if n_22640[i]=0 and n_22641[i]>0 then shift_mix[i]=n_22641[i];
	  else if n_22640[i]=1 then shift_mix[i]=work_year[i];
	  else if n_22640[i]=9 then shift_mix[i]=0;
	  if n_22640[i] in (0,1) then mix_day[i]=n_22643[i]*shift_mix[i];else mix_day[i]=0;

      if n_22650[i]=0 and n_22651[i]=-1001 then shift_night[i]=0.5;
	  else if n_22650[i]=0 and n_22651[i]>0 then shift_night[i]=n_22651[i];
	  else if n_22650[i]=1 then shift_night[i]=work_year[i];
	  else if n_22650[i]=9 then shift_night[i]=0;
	  if n_22650[i] in (0,1) then night_day[i]=n_22653[i]*shift_night[i];else night_day[i]=0;
	end;
	else if n_22620[i]=0 then do;
         shift_day[i]=0;shift_mix[i]=0;shift_night[i]=0;mix_day[i]=0;night_day[i]=0;
	end;
end;drop i;
shift_year=sum(of shift_day[*])+sum(of shift_mix[*])+sum(of shift_night[*]);
shift_day_year=sum(of shift_day[*]);
shift_night_year=sum(of shift_mix[*])+sum(of shift_night[*]);
if sum(of shift_mix[*])+sum(of shift_night[*])>0 then shift_freq=(sum(of mix_day[*])+sum(of night_day[*]))/(sum(of shift_mix[*])+sum(of shift_night[*]));
else shift_freq=0;

if shift_year=0 then grade_shift=1;
else if shift_year<10 then grade_shift=2;
else if shift_year>=10 then grade_shift=3;

if shift_day_year=0 then grade_shift_day=1;
else if shift_day_year<10 then grade_shift_day=2;
else if shift_day_year>=10 then grade_shift_day=3;

if shift_night_year=0 then grade_shift_night=1;
else if shift_night_year<10 then grade_shift_night=2;
else if shift_night_year>=10 then grade_shift_night=3;

if shift_freq=0 then grade_shift_freq=1;
else if shift_freq<8 then grade_shift_freq=2;
else grade_shift_freq=3;

*WEEs;
array n_22606[40] n_22606_0_0-n_22606_0_39;*noise;
array n_22607[40] n_22607_0_0-n_22607_0_39;*cold;
array n_22608[40] n_22608_0_0-n_22608_0_39;*hot;
array n_22609[40] n_22609_0_0-n_22609_0_39;*dusty;
array n_22610[40] n_22610_0_0-n_22610_0_39;*chemical;
array n_22611[40] n_22611_0_0-n_22611_0_39;*cigarette;
array n_22612[40] n_22612_0_0-n_22612_0_39;*asbestos;
array n_22613[40] n_22613_0_0-n_22613_0_39;*paint;
array n_22614[40] n_22614_0_0-n_22614_0_39;*pesticide;
array n_22615[40] n_22615_0_0-n_22615_0_39;*diesel;

array array_noasbestos[*] n_22606_: n_22607_: n_22608_: n_22609_: n_22610_: n_22611_: n_22613_: n_22614_: n_22615_:;
do i=1 to dim(array_noasbestos);
   if array_noasbestos[i]=-121 then array_noasbestos[i]=.;
   else if array_noasbestos[i]=-131 then array_noasbestos[i]=0;
   else if array_noasbestos[i]=-141 then array_noasbestos[i]=1;
end;drop i;

do i=1 to 40;
   if n_22612[i]=-121 then do;
      noasbestos=1;leave;
   end;
end;drop i;

do i=1 to 40;
   if n_22612[i]=-121 then n_22612[i]=0;
   else if n_22612[i]=-131 then n_22612[i]=0;
   else if n_22612[i]=-141 then n_22612[i]=1;
end;drop i;

*Lifetime WEEs;
do i=1 to 40;
   if work_year[i]>0 then do;
      if nmiss(n_22606[i],n_22607[i],n_22608[i],n_22609[i],n_22610[i],n_22611[i],n_22612[i],n_22613[i],n_22614[i],n_22615[i])=0;
   end;
end;drop i;

array all[*]all_0-all_39;
do i=1 to 40;
   if max(n_22606[i],n_22607[i],n_22608[i],n_22609[i],n_22610[i],n_22611[i],n_22612[i],n_22613[i],n_22614[i],n_22615[i])=1 then all[i]=1;
   else all[i]=0;
end;drop i;

array substance[*]substance_0-substance_39;
do i=1 to 40;
   if max(n_22609[i],n_22610[i],n_22612[i],n_22613[i],n_22614[i],n_22615[i])=1 then substance[i]=1;
   else substance[i]=0;
end;drop i;

array temp[*]temp_0-temp_39;
do i=1 to 40;
   if max(n_22607[i],n_22608[i])=1 then temp[i]=1;
   else temp[i]=0;
end;drop i;

all_year=0;substance_year=0;cigarette_year=0;temp_year=0;noise_year=0;
do i=1 to 40;
   if work_year[i]>0 then do;
      all_year=all_year+all[i]*work_year[i];
	  substance_year=substance_year+substance[i]*work_year[i];
	  cigarette_year=cigarette_year+n_22611[i]*work_year[i];
      temp_year=temp_year+temp[i]*work_year[i];
      noise_year=noise_year+n_22606[i]*work_year[i];
	  end;
end;drop i;

if all_year=0 then grade_all=1;
else if all_year<10 then grade_all=2;
else grade_all=3;

if substance_year=0 then grade_substance=1;
else if substance_year<10 then grade_substance=2;
else grade_substance=3;

if cigarette_year=0 then grade_cigarette=1;
else if cigarette_year<10 then grade_cigarette=2;
else grade_cigarette=3;

if temp_year=0 then grade_temp=1;
else if temp_year<10 then grade_temp=2;
else grade_temp=3;

if noise_year=0 then grade_noise=1;
else if noise_year<10 then grade_noise=2;
else grade_noise=3;

length combined_all$50;
if grade_all=1 and grade_shift=1 then combined_all='Never both';
else if grade_all=3 and grade_shift=3 then combined_all='Severe both';
else if grade_all=3 then combined_all='Only severe environment';
else if grade_shift=3 then combined_all='Only severe shift';
else if grade_all in (1,2) and grade_shift in (1,2) then combined_all='No severe';

length combined_substance$50;
if grade_substance=1 and grade_shift=1 then combined_substance='Never both';
else if grade_substance=3 and grade_shift=3 then combined_substance='Severe both';
else if grade_substance=3 then combined_substance='Only severe environment';
else if grade_shift=3 then combined_substance='Only severe shift';
else if grade_substance in (1,2) and grade_shift in (1,2) then combined_substance='No severe';

length combined_cigarette$50;
if grade_cigarette=1 and grade_shift=1 then combined_cigarette='Never both';
else if grade_cigarette=3 and grade_shift=3 then combined_cigarette='Severe both';
else if grade_cigarette=3 then combined_cigarette='Only severe environment';
else if grade_shift=3 then combined_cigarette='Only severe shift';
else if grade_cigarette in (1,2) and grade_shift in (1,2) then combined_cigarette='No severe';

length combined_temp$50;
if grade_temp=1 and grade_shift=1 then combined_temp='Never both';
else if grade_temp=3 and grade_shift=3 then combined_temp='Severe both';
else if grade_temp=3 then combined_temp='Only severe environment';
else if grade_shift=3 then combined_temp='Only severe shift';
else if grade_temp in (1,2) and grade_shift in (1,2) then combined_temp='No severe';

length combined_noise$50;
if grade_noise=1 and grade_shift=1 then combined_noise='Never both';
else if grade_noise=3 and grade_shift=3 then combined_noise='Severe both';
else if grade_noise=3 then combined_noise='Only severe environment';
else if grade_shift=3 then combined_noise='Only severe shift';
else if grade_noise in (1,2) and grade_shift in (1,2) then combined_noise='No severe';



if n_31_0_0=0 then gender=2;
else if n_31_0_0=1 then gender=1;

length race$50;
if n_21000_0_0 in (1,1001,1002,1003) then race='White';
else if n_21000_0_0 in (4,4001,4002,4003) then race='Black';
else if n_21000_0_0 in (3,3001,3002,3003,3004,5) then race='Asian';
else if n_21000_0_0 in (2,2001,2002,2003,2004) then race='Mixed';
else if n_21000_0_0=6 then race='Others';
if race='' then race='Missing';

length residence$50;
if n_20118_0_0 in (1,5,11,12) then residence='Urban';
else if n_20118_0_0>=1 and n_20118_0_0^=9 then residence='Town or rural';
if residence='' then residence='Missing';

length assessmentcentre$50;
if n_54_0_0 in (11012,11018)then assessmentcentre="London Area";
else if n_54_0_0 in (11005,11004)then assessmentcentre="Scotland";
else if n_54_0_0 in (11003,11022,11023)then assessmentcentre="Wales";
else if n_54_0_0 in (11009,11016,11001,11017,11010)then assessmentcentre="Northern England";
else if n_54_0_0 in (11021,11024,11013,11006,10003)then assessmentcentre="Central England";
else if n_54_0_0 in (11011,11008,11020,11002,11007,11014)then assessmentcentre="Southern England";

array array_education[*] n_6138_0_0-n_6138_0_5;
length education$50;
do i=1 to 6;
   if array_education[i] in (1,6) then do;
      education='High Level/Professional';leave;
   end;
   else if array_education[i] in (2,5) then do;
      education='Intermediate Level';leave;
   end;
   else if array_education[i] in (3,4) then do;
      education='Basic Level';leave;
   end;
   else if array_education[i]=-7 then do;
      education='Others';leave;
   end;
end;
if education='' then education='Missing';

if n_26410_0_0>. then do;MDI=n_26410_0_0;MDI_cat=1;end;
else if n_26426_0_0>. then do;MDI=n_26426_0_0;MDI_cat=2;end;
else if n_26427_0_0>. then do;MDI=n_26427_0_0;MDI_cat=3;end;

length birthcountry$50;
if n_1647_0_0 in (1,2,3,4) then birthcountry='UK';
else if n_1647_0_0=5 then birthcountry='Republic of Ireland';
else if n_1647_0_0=6 then birthcountry='Elsewhere';
if birthcountry='' then birthcountry='Missing';
run;
proc freq data=raw_UKB;
table grade_: combined_:;
run;
proc sort data=raw_UKB;by MDI_cat;run;
proc standard data=raw_UKB out=MDI_UKB std=1 mean=0;
by MDI_cat;
var MDI;
run;
proc sort data=MDI_UKB;by n_eid;run;
proc univariate data=MDI_UKB noprint;
var MDI;
output out=MDI_p pctlpts=33.33 66.66 pctlpre=P_;
run;
data _NULL_;
set MDI_p;
call symputx('tertile_1', P_33_33);
call symputx('tertile_2', P_66_66);
run;
data UKB_origin;
set MDI_UKB;
if MDI>. then do;
   length tertile_MDI$50;
   if MDI<=&tertile_1 then tertile_MDI='Mild deprivation';
   else if MDI<=&tertile_2 then tertile_MDI='Moderate deprivation';
   else tertile_MDI='Severe deprivation';
end;
if tertile_MDI='' then tertile_MDI='Missing';
run;
proc freq data=UKB_origin;
table tertile_MDI;
run;

data UKB_final;
set UKB_origin;
array s_41270[*] $s_41270_:;
array s_41280[*]  s_41280_:;
array self_cancercode[*] n_20001_0:;
array self_noncancercode[*] n_20002_0_:;
array code_cancer_reg[*] cancer_registry:;
array date_cancer_reg[*] date_cancer_registry:;
array death_code[*] s_40001_0_0 s_40002_0_:;

*Premature death;
death_date=s_40000_0_0;
if missing(death_date)=0 then new_death=1;
else do;new_death=0;death_date='19DEC2022'd;end;
age_death=YRDIF(birthdate,death_date,'ACTUAL');

*Cancer;
do i=1 to 6;
   if self_cancercode[i]>. then do;
      ever_cancer=1;leave;
   end;
end;drop i;
format date_cancer_registry date9.;
do i=1 to 22;
   if code_cancer_reg[i] in:('C') then do;
      date_cancer_registry=date_cancer_reg[i];leave;
   end;
end;drop i;
format cancer_death_date date9.;
do i=1 to dim(death_code);
   if death_code[i] in:('C') then do;
      cancer_death_date=s_40000_0_0;leave;
   end;
end;drop i;
format date_cancer_hospital date9.;
do i=1 to 259;
   if s_41270[i] in:('C') then do;
      date_cancer_hospital=s_41280[i];leave;
   end;
end;drop i;
format cancer_date date9.;
cancer_date=min(date_cancer_registry,cancer_death_date,date_cancer_hospital);
if ever_cancer^=1 AND (cancer_date=. OR cancer_date>s_53_0_0) then do;
   if cancer_date>s_53_0_0 then do;
      new_cancer=1;age_cancer=YRDIF(birthdate,cancer_date,'ACTUAL');
   end;
   else do;
      new_cancer=0;age_cancer=YRDIF(birthdate,'19DEC2022'd,'ACTUAL');
   end;
end;
if new_cancer=1 AND age_cancer>=70 then new_cancer=0;
if age_cancer>=70 then age_cancer=70;
time_cancer=age_cancer-age;

*Diabetes;
array array_diabetes_date[*] first_E10-first_E14;
format diabetes_date date9.;diabetes_date=min(of array_diabetes_date[*]);
if diabetes_date=. or diabetes_date>s_53_0_0 then do;
   if diabetes_date>s_53_0_0 then do;
      new_diabetes=1;age_diabetes=YRDIF(birthdate,diabetes_date,'ACTUAL');
   end;
   else do;
      new_diabetes=0;age_diabetes=YRDIF(birthdate,'01JUL2023'd,'ACTUAL');
   end;
end;
if n_30750_0_0>48 then do;new_diabetes=.;age_diabetes=.;end;

*Depression;
array array_depression_date[*] first_F32 first_F33;
format depression_date date9.;depression_date=min(of array_depression_date[*]);
if depression_date=. or depression_date>s_53_0_0 then do;
   if depression_date>s_53_0_0 then do;
      new_depression=1;age_depression=YRDIF(birthdate,depression_date,'ACTUAL');
   end;
   else do;
      new_depression=0;age_depression=YRDIF(birthdate,'01MAY2023'd,'ACTUAL');
   end;
end;

*Anxiety;
array array_anxiety_date[*] first_F40 first_F41;
format anxiety_date date9.;anxiety_date=min(of array_anxiety_date[*]);
if anxiety_date=. or anxiety_date>s_53_0_0 then do;
   if anxiety_date>s_53_0_0 then do;
      new_anxiety=1;age_anxiety=YRDIF(birthdate,anxiety_date,'ACTUAL');
   end;
   else do;
      new_anxiety=0;age_anxiety=YRDIF(birthdate,'01MAY2023'd,'ACTUAL');
   end;
end;

*Migraine;
format migraine_date date9.;migraine_date=first_G43;
if migraine_date=. or migraine_date>s_53_0_0 then do;
   if migraine_date>s_53_0_0 then do;
      new_migraine=1;age_migraine=YRDIF(birthdate,migraine_date,'ACTUAL');
   end;
   else do;
      new_migraine=0;age_migraine=YRDIF(birthdate,'28SEP2022'd,'ACTUAL');
   end;
end;

*Carpal tunnel syndrome;
do i=1 to dim(self_noncancercode);
   if self_noncancercode[i]=1541 then do;
      ever_carpal=1;leave;
   end;
end;drop i;
format carpal_hospital_date date9.;
do i=1 to 259;
   if s_41270[i] in:('G560') then do;
      carpal_hospital_date=s_41280[i];leave;
   end;
end;drop i;
format carpal_death_date date9.;
do i=1 to dim(death_code);
   if death_code[i] in:('G560') then do;
      carpal_death_date=s_40000_0_0;leave;
   end;
end;drop i;
array array_carpal_date[*] carpal_hospital_date carpal_death_date;
format carpal_date date9.;carpal_date=min(of array_carpal_date[*]);
if ever_carpal^=1 AND (carpal_date=. OR carpal_date>s_53_0_0) then do;
   if carpal_date>s_53_0_0 then do;
      new_carpal=1;age_carpal=YRDIF(birthdate,carpal_date,'ACTUAL');
   end;
   else if carpal_date=. then do;
      new_carpal=0;age_carpal=YRDIF(birthdate,'31OCT2022'd,'ACTUAL');
   end;
end;

*Sensory impairment;
array array_SI_date[*] first_H53 first_H54 first_90 first_H91;
format SI_date date9.;SI_date=min(of array_SI_date[*]);
if SI_date=. or SI_date>s_53_0_0 then do;
   if SI_date>s_53_0_0 then do;
      new_SI=1;age_SI=YRDIF(birthdate,SI_date,'ACTUAL');
   end;
   else do;
      new_SI=0;age_SI=YRDIF(birthdate,'31OCT2022'd,'ACTUAL');
   end;
end;

*Heart;
array array_heart_date[*] first_I05-first_I09 first_I11 first_I13 first_I20-first_I52;
format heart_date date9.;heart_date=min(of array_heart_date[*]);
if heart_date=. or heart_date>s_53_0_0 then do;
   if heart_date>s_53_0_0 then do;
      new_heart=1;age_heart=YRDIF(birthdate,heart_date,'ACTUAL');
   end;
   else do;
      new_heart=0;age_heart=YRDIF(birthdate,'01JUL2023'd,'ACTUAL');
   end;
end;

*Cerebrovascular disease;
array array_cerebrovascular_date[*] first_I60-first_I69 first_G45 first_G46;
format cerebrovascular_date date9.;cerebrovascular_date=min(of array_cerebrovascular_date[*]);
if cerebrovascular_date=. or cerebrovascular_date>s_53_0_0 then do;
   if cerebrovascular_date>s_53_0_0 then do;
      new_cerebrovascular=1;age_cerebrovascular=YRDIF(birthdate,cerebrovascular_date,'ACTUAL');
   end;
   else do;
      new_cerebrovascular=0;age_cerebrovascular=YRDIF(birthdate,'01JUL2023'd,'ACTUAL');
   end;
end;

*Peripheral vascular disease;
array array_PAD_date[*] first_I70-first_I73;
format PAD_date date9.;PAD_date=min(of array_PAD_date[*]);
if PAD_date=. or PAD_date>s_53_0_0 then do;
   if PAD_date>s_53_0_0 then do;
      new_PAD=1;age_PAD=YRDIF(birthdate,PAD_date,'ACTUAL');
   end;
   else do;
      new_PAD=0;age_PAD=YRDIF(birthdate,'18OCT2022'd,'ACTUAL');
   end;
end;

*Chronic obstructive pulmonary disease;
array array_COPD_date[*] first_J41-first_J44;
format COPD_date date9.;COPD_date=min(of array_COPD_date[*]);
if COPD_date=. or COPD_date>s_53_0_0 then do;
   if COPD_date>s_53_0_0 then do;
      new_COPD=1;age_COPD=YRDIF(birthdate,COPD_date,'ACTUAL');
   end;
   else do;
      new_COPD=0;age_COPD=YRDIF(birthdate,'25OCT2022'd,'ACTUAL');
   end;
end;

*Asthma;
array array_asthma_date[*] first_J45-first_J46;
format asthma_date date9.;asthma_date=min(of array_asthma_date[*]);
if asthma_date=. or asthma_date>s_53_0_0 then do;
   if asthma_date>s_53_0_0 then do;
      new_asthma=1;age_asthma=YRDIF(birthdate,asthma_date,'ACTUAL');
   end;
   else do;
      new_asthma=0;age_asthma=YRDIF(birthdate,'24OCT2022'd,'ACTUAL');
   end;
end;

*Gastritis and duodenitis;
format gastritis_date date9.;gastritis_date=first_K29;
if gastritis_date=. or gastritis_date>s_53_0_0 then do;
   if gastritis_date>s_53_0_0 then do;
      new_gastritis=1;age_gastritis=YRDIF(birthdate,gastritis_date,'ACTUAL');
   end;
   else do;
      new_gastritis=0;age_gastritis=YRDIF(birthdate,'26OCT2022'd,'ACTUAL');
   end;
end;

*Irritable bowel syndrome;
format IBS_date date9.;IBS_date=first_K58;
if IBS_date=. or IBS_date>s_53_0_0 then do;
   if IBS_date>s_53_0_0 then do;
      new_IBS=1;age_IBS=YRDIF(birthdate,IBS_date,'ACTUAL');
   end;
   else do;
      new_IBS=0;age_IBS=YRDIF(birthdate,'26OCT2022'd,'ACTUAL');
   end;
end;

*Liver disease;
array array_liver_date[*] first_K70-first_K77;
format liver_date date9.;liver_date=min(of array_liver_date[*]);
if liver_date=. or liver_date>s_53_0_0 then do;
   if liver_date>s_53_0_0 then do;
      new_liver=1;age_liver=YRDIF(birthdate,liver_date,'ACTUAL');
   end;
   else do;
      new_liver=0;age_liver=YRDIF(birthdate,'29OCT2022'd,'ACTUAL');
   end;
end;

*Psoriasis;
format psoriasis_date date9.;psoriasis_date=first_L40;
if psoriasis_date=. or psoriasis_date>s_53_0_0 then do;
   if psoriasis_date>s_53_0_0 then do;
      new_psoriasis=1;age_psoriasis=YRDIF(birthdate,psoriasis_date,'ACTUAL');
   end;
   else do;
      new_psoriasis=0;age_psoriasis=YRDIF(birthdate,'01FEB2023'd,'ACTUAL');
   end;
end;

*Arthritis;
array array_arthritis_date[*] first_M05-first_M19;
format arthritis_date date9.;arthritis_date=min(of array_arthritis_date[*]);
if arthritis_date=. or arthritis_date>s_53_0_0 then do;
   if arthritis_date>s_53_0_0 then do;
      new_arthritis=1;age_arthritis=YRDIF(birthdate,arthritis_date,'ACTUAL');
   end;
   else do;
      new_arthritis=0;age_arthritis=YRDIF(birthdate,'01JUL2023'd,'ACTUAL');
   end;
end;

*Spondylopathy;
array array_spondylopathy_date[*] first_M45-first_M49;
format spondylopathy_date date9.;spondylopathy_date=min(of array_spondylopathy_date[*]);
if spondylopathy_date=. or spondylopathy_date>s_53_0_0 then do;
   if spondylopathy_date>s_53_0_0 then do;
      new_spondylopathy=1;age_spondylopathy=YRDIF(birthdate,spondylopathy_date,'ACTUAL');
   end;
   else do;
      new_spondylopathy=0;age_spondylopathy=YRDIF(birthdate,'01MAY2023'd,'ACTUAL');
   end;
end;

*Intervertebral disk disease;
array array_intervertebral_date[*] first_M50-first_M51;
format intervertebral_date date9.;intervertebral_date=min(of array_intervertebral_date[*]);
if intervertebral_date=. or intervertebral_date>s_53_0_0 then do;
   if intervertebral_date>s_53_0_0 then do;
      new_intervertebral=1;age_intervertebral=YRDIF(birthdate,intervertebral_date,'ACTUAL');
   end;
   else do;
      new_intervertebral=0;age_intervertebral=YRDIF(birthdate,'01JUL2023'd,'ACTUAL');
   end;
end;

*Renal failure;
array array_RF_date[*] first_N17-first_N19;
format RF_date date9.;RF_date=min(of array_RF_date[*]);
if RF_date=. or RF_date>s_53_0_0 then do;
   if RF_date>s_53_0_0 then do;
      new_RF=1;age_RF=YRDIF(birthdate,RF_date,'ACTUAL');
   end;
   else do;
      new_RF=0;age_RF=YRDIF(birthdate,'25OCT2022'd,'ACTUAL');
   end;
end;

array outcome_array[*] new_death new_cancer new_diabetes new_depression new_anxiety new_migraine new_carpal 
                       new_SI new_heart new_cerebrovascular new_PAD new_COPD new_asthma new_gastritis 
                       new_IBS new_liver new_psoriasis new_arthritis new_spondylopathy new_intervertebral new_RF;
array age_array[*] age_death age_cancer age_diabetes age_depression age_anxiety age_migraine age_carpal 
                   age_SI age_heart age_cerebrovascular age_PAD age_COPD age_asthma age_gastritis 
                   age_IBS age_liver age_psoriasis age_arthritis age_spondylopathy age_intervertebral age_RF;
array time_array[*] time_death time_cancer time_diabetes time_depression time_anxiety time_migraine time_carpal 
                    time_SI time_heart time_cerebrovascular time_PAD time_COPD time_asthma time_gastritis 
                    time_IBS time_liver time_psoriasis time_arthritis time_spondylopathy time_intervertebral time_RF;
do i=1 to dim(outcome_array);
   if outcome_array[i]=1 AND age_array[i]>=70 then outcome_array[i]=0;
   if age_array[i]>=70 then age_array[i]=70;
   time_array[i]=age_array[i]-age;
end;
run;
proc freq data=UKB_final;
table new_:;
run;
proc means data=UKB_final;
var time_:;
run;



%macro Cox(data=,explist=,ref=,by=,outcomelist=);
%do i=1 %to %sysfunc(countw(&explist));
%do j=1 %to %sysfunc(countw(&outcomelist));
   %let exp=%scan(&explist, &i);
   %let outcome=%scan(&outcomelist, &j);
   %if "&by" ne "" %then %do;
      proc sort data=&data;
      by &by;
      run;
      proc phreg data=&data;
      by &by;
   %end;
   %else %do;
      proc phreg data=&data;
   %end;
      %if "&ref" ne "" %then %do;
         class &exp(ref="&ref") &class/param=ref;
      %end;
      %else %do;
         class &class/param=ref;
      %end;
   model time_&outcome*new_&outcome(0)=&exp &covariate/rl ties=efron;
   ods output ParameterEstimates=myresults;
   run;

   %if "&by" ne "" %then %do;
      proc phreg data=&data;
         %if "&ref" ne "" %then %do;
            class &exp(ref="&ref") &by &class/param=ref;
         %end;
         %else %do;
            class &by &class/param=ref;
         %end;
      model time_&outcome*new_&outcome(0)=&exp|&by &covariate/rl ties=efron;
	  ods output ModelANOVA=myresults_p;
      run;

      data p;
      set myresults_p;
      length param$20;
      param=lowcase(Effect);
      if index(param,"*")>0;
      keep param ProbChiSq;
      run;
      proc append base=p2 data=p;
      run;
   %end;

   data new_myresults;
   set myresults;
   length param$20;
   param=Parameter;
   length=length("&exp");
   if length>=20 then length=20;
   if substr(lowcase(param),1,length)=substr(lowcase("&exp"),1,length);
   HR=cat(put(round(HazardRatio,0.01),8.2), ' (', cats(put(round(HRLowerCL,0.01), 8.2), '-', put(round(HRUpperCL,0.01), 8.2),')'));
   keep param HR ProbChiSq;
   run;

   proc append base=new_myresults2 data=new_myresults;
   run;
%end;%end;

%if "&by" ne "" %then %do;
   proc print data=p2;
   var param ProbChiSq;
   run;
   proc delete data=p2;
   run;
%end;

proc print data=new_myresults2;
var param HR ProbChiSq;
run;
proc delete data=new_myresults2;
run
%mend;
%let class=gender race residence assessmentcentre education tertile_MDI jobcount MainJob grade_hour birthcountry;
%let covariate=age gender race residence assessmentcentre education tertile_MDI jobcount MainJob grade_hour birthcountry;

%let longterm=cancer diabetes depression anxiety migraine carpal SI 
              heart cerebrovascular PAD COPD asthma gastritis IBS 
              liver psoriasis arthritis spondylopathy intervertebral RF;

%Cox(data=UKB_final,explist=grade_all,ref=1,outcomelist=&longterm);
%Cox(data=UKB_final,explist=all_year,outcomelist=&longterm);

%Cox(data=UKB_final,explist=grade_substance grade_cigarette grade_temp grade_noise,ref=1,outcomelist=&longterm);
%Cox(data=UKB_final,explist=substance_year cigarette_year temp_year noise_year,outcomelist=&longterm);

%Cox(data=UKB_final,explist=grade_shift,ref=1,outcomelist=&longterm);
%Cox(data=UKB_final,explist=shift_year,outcomelist=&longterm);

%Cox(data=UKB_final,explist=grade_shift_day,ref=1,outcomelist=&longterm);
%Cox(data=UKB_final,explist=shift_day_year,outcomelist=&longterm);

%Cox(data=UKB_final,explist=grade_shift_night,ref=1,outcomelist=&longterm);
%Cox(data=UKB_final,explist=shift_night_year,outcomelist=&longterm);

%Cox(data=UKB_final,explist=grade_shift_freq,ref=1,outcomelist=&longterm);
%Cox(data=UKB_final,explist=shift_freq,outcomelist=&longterm);

*Joint;
%Cox(data=UKB_final,explist=combined_all,ref=Never both,outcomelist=&longterm);
%Cox(data=UKB_final,explist=grade_all,ref=1,outcomelist=&longterm,by=grade_shift);

proc freq data=UKB_final;
table combined_substance;
run;
%Cox(data=UKB_final,explist=combined_substance,ref=Never both,outcomelist=&longterm);
%Cox(data=UKB_final,explist=grade_substance,ref=1,outcomelist=&longterm,by=grade_shift);

proc freq data=UKB_final;
table combined_cigarette;
run;
%Cox(data=UKB_final,explist=combined_cigarette,ref=Never both,outcomelist=&longterm);
%Cox(data=UKB_final,explist=grade_cigarette,ref=1,outcomelist=&longterm,by=grade_shift);

proc freq data=UKB_final;
table combined_temp;
run;
%Cox(data=UKB_final,explist=combined_temp,ref=Never both,outcomelist=&longterm);
%Cox(data=UKB_final,explist=grade_temp,ref=1,outcomelist=&longterm,by=grade_shift);

proc freq data=UKB_final;
table combined_noise;
run;
%Cox(data=UKB_final,explist=combined_noise,ref=Never both,outcomelist=&longterm);
%Cox(data=UKB_final,explist=grade_noise,ref=1,outcomelist=&longterm,by=grade_shift);

*Gender-stratified;
%Cox(data=UKB_final,explist=grade_all,ref=1,outcomelist=&longterm,by=gender);
%Cox(data=UKB_final,explist=grade_shift,ref=1,outcomelist=&longterm,by=gender);
