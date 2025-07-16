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

    # Patch in missing buckets (0 durations)
    patched = add_missing_buckets(agg, start_date, end_date, bucket_size)

    # Calculate max duration (in minutes) for scaling
    all_durations = [d['duration'].total_seconds() / 60 for d in patched]
    time_span = (end_date - start_date).total_seconds()

    max_duration_min = max(item['duration'].total_seconds() / 60 for item in patched) if patched else 0
    padding = 10  # extra space above the tallest bar/node
    unit_height = 1

    nodes = []
    points = []  # Store points for recalculation

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

        node_data = {
            'x': x, 
            'y': y, 
            'label': label,
            'duration_min': duration_min,
            'timestamp': ts,
            'bucket_size': bucket_size
        }
        nodes.append(node_data)
        
        # Store points for potential recalculation
        points.append({
            'timestamp': ts,
            'duration_min': duration_min,
            'x_percent': x_percent
        })

    # Add points to nodes for recalculation capability
    for node in nodes:
        node['points'] = points

    return nodes


def filter_by_project(df, project_name):
    """Returns a new DataFrame containing only rows for the given project."""
    return df[df['project'] == project_name].copy()

def add_missing_buckets(agg, start_date, end_date, bucket_size=7):
    """
    Returns a list of dicts, one per bucket period, with 0 duration if missing from agg.
    Handles different bucket sizes dynamically.
    """
    all_buckets = []
    
    if bucket_size == 7:
        # Weekly buckets starting on Monday
        current = start_date - timedelta(days=start_date.weekday())
        while current <= end_date:
            all_buckets.append(current)
            current += timedelta(days=7)
    else:
        # Daily buckets with specified size
        current = start_date
        while current <= end_date:
            all_buckets.append(current)
            current += timedelta(days=bucket_size)

    # Convert existing buckets to a dict for quick lookup
    duration_lookup = {row['bucket']: row['duration'] for _, row in agg.iterrows()}

    # Create full list with default durations
    result = []
    for b in all_buckets:
        duration = duration_lookup.get(b, timedelta(0))
        result.append({'bucket': b, 'duration': duration})

    return result

def recalculate_node_positions(nodes, start_date, end_date, graph_width=785):
    """
    Recalculates node positions when bucket size changes due to date range modification.
    """
    if not nodes:
        return nodes
    
    # Get the stored points from the first node
    points = nodes[0].get('points', [])
    if not points:
        return nodes
    
    total_days = (end_date - start_date).days
    bucket_size = get_bucket_size(total_days)
    time_span = (end_date - start_date).total_seconds()
    
    # Find max duration for scaling
    max_duration_min = max(point['duration_min'] for point in points) if points else 0
    padding = 10
    unit_height = 1
    
    # Recalculate positions for each node
    for i, node in enumerate(nodes):
        if i < len(points):
            point = points[i]
            
            # Recalculate X position
            x_percent = (point['timestamp'] - start_date).total_seconds() / time_span
            x = int(x_percent * graph_width)
            
            # Recalculate Y position
            duration_min = point['duration_min']
            if duration_min == 0:
                y = 310
            else:
                y = int((max_duration_min + padding - duration_min) * unit_height)
            
            # Update node
            node['x'] = x
            node['y'] = y
            node['bucket_size'] = bucket_size
    
    return nodes

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
