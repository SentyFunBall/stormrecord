from flask import Flask, request
import csv
import os
import time

app = Flask('app')
hitCount = 0

@app.route("/ping")
def ping():
    return "pong"

@app.route("/packet")
def packet():
    start = time.time()
    name = request.args.get("name") #Name of channel
    values = request.args.get("values").split(",") #the actual values

    global hitCount
    hitCount += 1

    print("Hit",hitCount,": Recieved",len(values), "values")

    try:
        write(name, values)
    except Exception as e:
        print("Err writing:", e)
        return "Error"

    end = time.time()
    length = end - start

    print("Request took",length*1000,"ms")
    
    return "Values recorded"

@app.route("/refresh")
def refresh():
    status = "Refreshed"
    global hitCount
    # Check if the file exists
    if os.path.exists('data.csv'):
        # Check if the file is empty
        if os.path.getsize('data.csv') > 0:
            # File is not empty, proceed with reading
            try:
                with open('data.csv', 'r') as f:
                    reader = csv.reader(f)
                    rows = list(reader)
            except FileNotFoundError as e:
                print("File not found:", e)
                status = "File not found"
            except csv.Error as e:
                print("CSV error:", e)
                status = "CSV error"
        else:
            print("File 'data.csv' is empty.")
    else:
        print("File 'data.csv' does not exist in same directory as python file")
        status = "File not found"

    rows = []

    with open('data.csv', 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerows(rows)
        print("CSV updated")

    hitCount = 0
    return status

def write(name, values):
    # Create empty list
    rows = []

    # Check if the file exists
    if os.path.exists('data.csv'):
        # Check if the file is empty
        if os.path.getsize('data.csv') > 0:
            # File is not empty, proceed with reading
            try:
                with open('data.csv', 'r') as f:
                    reader = csv.reader(f)
                    rows = list(reader)
            except FileNotFoundError as e:
                print("File not found:", e)
            except PermissionError as e:
                print("Permission error:", e)
            except csv.Error as e:
                print("CSV error:", e)
        else:
            print("File 'data.csv' is empty.")
    else:
        print("File 'data.csv' does not exist.")
        
    # Check if the sensor already exists
    name_index = -1
    if rows:
        for i, sensor_name in enumerate(rows[0]):
            if sensor_name == name:
                name_index = i
                break

    # If the sensor exists, we want to append to it
    if name_index != -1:
        # If we're working with the first sensor, create new lines
        if name == rows[0][0]:
            print("2.2")
            columns = len(rows)
            for i, value in enumerate(values):
                if columns <= columns + i + 1:
                    rows.append([])
                rows[columns + i].append(value)
        else: #It's not the first sensor, so append instead
            print("2.3")
            columns = column_length(rows, name_index)
            try:
                for i, value in enumerate(values):
                    rows[columns + i].append(value)
            except Exception as e:
                print("Err2.3:", e)
    else:
        if len(rows) > 0: #File exists, sensor doesn't
            print("2.4")
            rows[0].append(name) # Add sensor name...
            for i, value in enumerate(values):
                if len(rows) <= i + 1:
                    rows.append([])
                rows[i+1].append(value)
        else: #File doesn't exist
            print("2.5")
            try:
                rows.append([name])
                for i, value in enumerate(values):
                    if len(rows) <= i + 1:
                        rows.append([])
                    rows[i+1].append(value)
            except Exception as e:
                print("Err2.5:", e)

    # Write data back to CSV
    with open('data.csv', 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerows(rows)
        print("CSV updated")

def column_length(rows, col_index):
    # Check if the column index is valid
    if col_index < 0 or col_index >= len(rows[0]):
        return 0

    # Initialize a variable to store the column length
    col_length = 0

    # Iterate over the rows and count the number of elements in the specified column
    for row in rows:
        if len(row) > col_index:
            col_length += 1

    return col_length


app.run(host = '0.0.0.0', port=1575)