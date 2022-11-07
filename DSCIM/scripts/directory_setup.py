import yaml
import os
from pathlib import Path
import zipfile
from tqdm import *
import requests

base = os.getcwd()
input = Path(base) / "input"  
output = Path(base) / "output"  

def makedir(path):
    if not os.path.exists(path):
        os.makedirs(path)
        
    
climate_inputs = input / "climate"
econ_inputs = input / "econ"
damage_functions = input / "damage_functions"


conf_base = {'mortality_version': 1,
 'coastal_version': '0.20',
 'rff_climate': {'gases': ['CO2_Fossil', 'CH4', 'N2O'],
  'gmsl_path': '',
  'gmst_path': '',
  'gmst_fair_path': str(climate_inputs / 'gmst_pulse.nc'),
  'gmsl_fair_path': str(climate_inputs / 'gmsl_pulse.zarr'),
  'damages_pulse_conversion_path': str(climate_inputs / 'conversion_v5.03_Feb072022.nc4'),
  'ecs_mask_path': None,
  'emission_scenarios': None},
 'paths': {'rff_damage_function_library': str(damage_functions)},
 'rffdata': {'socioec_output': str(econ_inputs),
  'pulse_years': [2020, 2030, 2040, 2050, 2060, 2070, 2080]},
 'sectors': {'coastal_v0.20': {'formula': 'damages ~ -1 + gmsl + np.power(gmsl, 2)'},
  'agriculture': {'formula': 'damages ~ -1 + anomaly + np.power(anomaly, 2)'},
  'mortality_v1': {'formula': 'damages ~ -1 + anomaly + np.power(anomaly, 2)'},
  'energy': {'formula': 'damages ~ -1 + anomaly + np.power(anomaly, 2)'},
  'labor': {'formula': 'damages ~ -1 + anomaly + np.power(anomaly, 2)'},
  'AMEL_m1': {'formula': 'damages ~ -1 + anomaly + np.power(anomaly, 2)'},
  'CAMEL_m1_c0.20': {'formula': 'damages ~ -1 + anomaly + np.power(anomaly, 2) + gmsl + np.power(gmsl, 2)'}},
  'save_path': str(output)}
  
# Download inputs from internet  
print("Downloading input files...")
name = 'dscim_v20221021_inputs.zip'
url = 'https://storage.googleapis.com/climateimpactlab-scc-tool/dscim-epa_input_data/' + name
with requests.get(url, stream = True) as r:
    r.raise_for_status()
    with open(name, 'wb') as f:
        pbar = tqdm(total = int(r.headers['Content-Length']))
        for chunk in r.iter_content(chunk_size=8192):
            if chunk:  # filter out keep-alive new chunks
                f.write(chunk)
                pbar.update(len(chunk))
print("")
print("Unzipping input files...")
with zipfile.ZipFile(Path(base) /  name, 'r') as zip_ref:
    for member in tqdm(zip_ref.infolist()):
        try:
            zip_ref.extract(member, Path(base))
        except zipfile.error as e:
            pass

if os.path.exists(Path(base) / name):
    os.remove(Path(base) / name)
else:
    print("Download Failed")

os.rename(Path(base) / 'inputs', input)

with open('generated_conf.yml', 'w') as outfile:
    yaml.dump(conf_base, outfile, default_flow_style=False)
