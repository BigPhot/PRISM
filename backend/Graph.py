from PySide6.QtCore import QObject, Signal, Property, QAbstractListModel, Qt, QModelIndex
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
import json
import pandas as pd
from datetime import datetime, timedelta


def load_logs_for_dataframe(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)

    # Extract only the desired fields
    records = []
    for item in data:
        record = {
            'project': item.get('project'),
            'timestamp': item.get('timestamp'),
            'duration': item.get('duration')
        }
        records.append(record)

    # Create and return the DataFrame
    return pd.DataFrame(records)

def get_bucket_size(days):
    if days <= 7: return 1
    elif days <= 31: return 3
    elif days <= 90: return 7
    elif days <= 180: return 14
    elif days <= 365: return 30
    else: return 60

def parse_duration(s):
    try:
        parts = list(map(int, s.strip().split(":")))
        if len(parts) == 2:
            return timedelta(minutes=parts[0], seconds=parts[1])
        elif len(parts) == 3:
            return timedelta(hours=parts[0], minutes=parts[1], seconds=parts[2])
        else:
            return timedelta(0)
    except Exception:
        return timedelta(0)


def aggregate_nodes(df, start_date, end_date, graph_width=785):
    # Convert timestamps and durations
    df['timestamp'] = pd.to_datetime(df['timestamp'])
    df['duration'] = df['duration'].astype(str).apply(parse_duration)

    # Filter data within the visible range
    end_datetime = end_date + pd.Timedelta(days=1)
    mask = (df['timestamp'] >= start_date) & (df['timestamp'] <= end_datetime)
    df = df[mask].copy()

    total_days = (end_date - start_date).days
    bucket_size = get_bucket_size(total_days)

    # Assign bucket based on size
    if bucket_size == 7:
        df['bucket'] = df['timestamp'].dt.to_period('W').apply(lambda p: p.start_time)
    else:
        df['bucket'] = df['timestamp'].dt.floor(f'{bucket_size}D')

    # Aggregate durations
    agg = df.groupby('bucket')['duration'].sum().reset_index()

    # Patch in missing weeks (0 durations)
    patched = add_missing_buckets(agg, start_date, end_date)


    # Calculate max duration (in minutes) for scaling
    all_durations = [d['duration'].total_seconds() / 60 for d in patched]
    time_span = (end_date - start_date).total_seconds()

    max_duration_min = max(item['duration'].total_seconds() / 60 for item in patched)
    padding = 10  # extra space above the tallest bar/node
    unit_height= 1

    nodes = []

    for item in patched:
        ts = item['bucket']
        duration_min = item['duration'].total_seconds() / 60
        label = ts.strftime('%b %d')

        # X position remains percentage based
        x_percent = (ts - start_date).total_seconds() / time_span
        x = int(x_percent * graph_width)

        if duration_min == 0:
            y = 310
        else:
            # Absolute Y position (invert so 0 is bottom)
            y = int((max_duration_min + padding - duration_min) * unit_height)

        nodes.append({'x': x, 'y': y, 'label': label})

    return nodes


def filter_by_project(df, project_name):
    """Returns a new DataFrame containing only rows for the given project."""
    return df[df['project'] == project_name].copy()

def add_missing_buckets(agg, start_date, end_date):
    """
    Returns a list of dicts, one per week starting on Monday, with 0 duration if missing from agg.
    """
    # Get list of all Mondays between start_date and end_date
    current = start_date - timedelta(days=start_date.weekday())  # align to Monday
    all_buckets = []
    while current <= end_date:
        all_buckets.append(current)
        current += timedelta(days=7)

    # Convert existing buckets to a dict for quick lookup
    duration_lookup = {row['bucket']: row['duration'] for _, row in agg.iterrows()}

    # Create full list with default durations
    result = []
    for b in all_buckets:
        duration = duration_lookup.get(b, timedelta(0))
        result.append({'bucket': b, 'duration': duration})

    return result

def graph_nodes_creation(start_date, end_date, project):
    file = 'C:/Users/adhir/Development/PRISM/data/Task_Activity_Log.json'
    df = load_logs_for_dataframe(file)
    fdf = filter_by_project(df, project)
    nodes = aggregate_nodes(fdf, start_date, end_date)
    return nodes

if __name__ == '__main__':
    file = 'C:/Users/adhir/Developement/Personal_Dev/Tablet/PRISM/data/Task_Activity_Log.json'
    df = load_logs_for_dataframe(file)
    fdf = filter_by_project(df, 'Prism')

    visibleStart = datetime(2025, 5, 19)
    visibleEnd = datetime(2025, 6, 30)

    nodes = aggregate_nodes(fdf, visibleStart, visibleEnd)
    for n in nodes:
        print(n)
