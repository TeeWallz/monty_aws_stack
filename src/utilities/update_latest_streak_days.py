
import json
from datetime import datetime

filepath = 'src/frontend/src/data/chumps.json'

with open(filepath, 'r') as f:
  loaded_data = json.load(f)

print(loaded_data['chumps'][0]['streak'])

chump_1 = datetime.fromisoformat(loaded_data['chumps'][0]['date'])
chump_2 = datetime.fromisoformat(loaded_data['chumps'][1]['date'])


loaded_data['chumps'][0]['streak'] = (chump_1-chump_2).days


print(loaded_data['chumps'][0]['streak'])

with open(filepath, "w") as data_file:
    json.dump(loaded_data, data_file, indent=4)