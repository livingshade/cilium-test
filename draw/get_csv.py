import sys
import csv

if len(sys.argv) != 2:
    print("Usage: python script.py <input_file>")
    sys.exit()

input_file = sys.argv[1]

with open(input_file, 'r') as file:
    reader = csv.reader(file)
    data = list(reader)

num_cols = len(data[0])
num_rows = len(data)

averages = []

for i in range(num_cols):
    col_sum = 0
    for j in range(num_rows):
        if j == 0:
            continue;
        col_sum += float(data[j][i])
    col_avg = col_sum / (num_rows - 1)
    averages.append(col_avg)

print("Column Averages:")
for i in range(num_cols):
    print("Column {}: {}".format(i, averages[i]))
