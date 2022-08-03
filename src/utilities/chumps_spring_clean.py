
import json
from datetime import datetime

filepath = 'src/frontend/src/data/chumps.json'

print("Loading chumps")
with open(filepath, 'r') as f:
  loaded_data = json.load(f)


# Set streak for newest chump
print("Setting current streak")
now = datetime.now()
chump = datetime.fromisoformat(loaded_data['chumps'][0]['date'])
loaded_data['chumps'][0]['streak'] = (datetime.now()-chump).days

# Set the streak_max_proportion
print("Setting streak_max_proportion")
largestStreak = max(loaded_data['chumps'], key=lambda x:x['streak'])['streak']

for i, singleChump in enumerate(loaded_data['chumps']):
    additionAmount =  (largestStreak - singleChump['streak']) * 0.1
    finalAmount =  singleChump['streak'] + additionAmount
    singleChump['streak_max_proportion'] = round(finalAmount / largestStreak, 3)

    if i > 0 and i < len(loaded_data['chumps']) -2:
        current_chump_date = datetime.fromisoformat(loaded_data['chumps'][i]['date'])
        chump2 = datetime.fromisoformat(loaded_data['chumps'][i-1]['date'])

        singleChump['streak'] = (chump2-current_chump_date).days
        singleChump['date_aus_string'] = current_chump_date.strftime("%d/%m/%Y")
        singleChump['date_week'] = int(current_chump_date.isocalendar().week)
        singleChump['date_year'] = int(current_chump_date.isocalendar().year)
        singleChump['date_nice'] = current_chump_date.strftime("%A, %e %B %Y")

print("Saving file")
with open(filepath, "w") as data_file:
    json.dump(loaded_data, data_file, indent=4)