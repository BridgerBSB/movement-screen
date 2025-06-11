import streamlit as st
import pandas as pd
import datetime
import uuid
import os
import json

# Set page configuration
st.set_page_config(
    page_title="Softball Mobility Screen",
    page_icon="🥎",
    layout="wide"
)

# Initialize session state for data storage
if 'current_data' not in st.session_state:
    st.session_state.current_data = {}
if 'measurement_results' not in st.session_state:
    st.session_state.measurement_results = {}

# Define simplified measurement structure with 3 key mobility groups
MEASUREMENTS = {
    "Hips": {
        "R Hip ER": {"unit": "degrees", "min": 0, "max": 180},
        "R Hip IR": {"unit": "degrees", "min": 0, "max": 180},
        "L Hip ER": {"unit": "degrees", "min": 0, "max": 180},
        "L Hip IR": {"unit": "degrees", "min": 0, "max": 180}
    },
    "Tspine": {
        "Tspine Rot L": {"unit": "degrees", "min": 0, "max": 180},
        "Tspine Rot R": {"unit": "degrees", "min": 0, "max": 180}
    },
    "Shoulder": {
        "R Sh ER": {"unit": "degrees", "min": 0, "max": 180},
        "R Sh IR": {"unit": "degrees", "min": 0, "max": 180},
        "L Sh ER": {"unit": "degrees", "min": 0, "max": 180},
        "L Sh IR": {"unit": "degrees", "min": 0, "max": 180},
        "R Sh Flx": {"unit": "degrees", "min": 0, "max": 180},
        "L Sh Flx": {"unit": "degrees", "min": 0, "max": 180}
    }
}

def validate_inputs(name, event_id, age, weight, height):
    """Validate user inputs before saving"""
    errors = []
    
    if not name.strip():
        errors.append("Name is required")
    if not event_id.strip():
        errors.append("Event ID is required")
    if age < 0 or age > 100:
        errors.append("Age must be between 0 and 100")
    if weight < 0 or weight > 500:
        errors.append("Weight must be between 0 and 500 lbs")
    
    # Validate height format (basic check)
    if height and not any(char.isdigit() for char in height):
        errors.append("Height should contain numbers")
    
    return errors

# Function to save data
def save_data(data):
    """Save measurement data to JSON and CSV files"""
    try:
        # Create data directory if it doesn't exist
        if not os.path.exists("data"):
            os.makedirs("data")
        
        # Generate a unique filename based on athlete name and timestamp
        safe_name = "".join(c for c in data['name'] if c.isalnum() or c in (' ', '-', '_')).rstrip()
        filename = f"data/{safe_name.replace(' ', '_')}_{data['event_id']}_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        
        # Save the data as JSON
        with open(filename, "w") as f:
            json.dump(data, f, indent=2)
        
        # Also append to a CSV for easy aggregation
        df_new = pd.DataFrame([data])
        
        if os.path.exists("data/all_screens.csv"):
            try:
                df_existing = pd.read_csv("data/all_screens.csv")
                
                # Get complete set of columns from both frames
                all_columns = list(set(df_new.columns) | set(df_existing.columns))
                
                # Ensure both frames have all columns
                for col in all_columns:
                    if col not in df_existing.columns:
                        df_existing[col] = None
                    if col not in df_new.columns:
                        df_new[col] = None
                
                # Combine both dataframes
                df_combined = pd.concat([df_existing, df_new], ignore_index=True)
                df_combined.to_csv("data/all_screens.csv", index=False)
            except Exception as e:
                st.warning(f"Could not append to existing CSV: {e}")
                # Create new CSV with just current data
                df_new.to_csv("data/all_screens.csv", index=False)
        else:
            # No existing CSV, create new
            df_new.to_csv("data/all_screens.csv", index=False)
        
        return filename
    
    except Exception as e:
        st.error(f"Error saving data: {e}")
        return None

# Initialize measurement results in session state if not already present
if 'measurement_results' not in st.session_state:
    st.session_state.measurement_results = {}
    for group in MEASUREMENTS:
        for measurement in MEASUREMENTS[group]:
            key = f"{group}_{measurement}"
            st.session_state.measurement_results[key] = 0  # Default to 0 degrees

# Header section
st.title("🥎 Softball Mobility Screen")
st.markdown("### Range of Motion Assessment Tool")

# Create two columns for the form layout
col1, col2 = st.columns(2)

with col1:
    event_id = st.text_input("Event ID:", key="event_id", placeholder="e.g., CAMP2024-001")
    name = st.text_input("Athlete Name:", key="name", placeholder="Enter full name")
    age = st.number_input("Age:", min_value=0, max_value=100, step=1, key="age")
    date = st.date_input("Assessment Date:", datetime.datetime.now(), key="date")

with col2:
    throws = st.selectbox("Throws:", ["Right", "Left", "Switch"], key="throws")
    hits = st.selectbox("Hits:", ["Right", "Left", "Switch"], key="hits")
    weight = st.number_input("Weight (lbs):", min_value=0, max_value=500, step=1, key="weight")
    height = st.text_input("Height:", key="height", placeholder="e.g., 5'8\" or 68 inches")

st.divider()

# Create tabs for each measurement group
tabs = st.tabs([f"🏃 {group}" for group in MEASUREMENTS.keys()])

# Fill out measurement group tabs
for i, group in enumerate(MEASUREMENTS.keys()):
    with tabs[i]:
        st.header(f"{group} Range of Motion")
        st.markdown(f"*Record measurements in degrees (0-180°)*")
        
        # Create each measurement within the group
        for measurement in MEASUREMENTS[group]:
            # Generate a unique key for this measurement
            measurement_key = f"{group}_{measurement}"
            
            # Create columns for better layout
            col1, col2 = st.columns([3, 1])
            
            with col1:
                st.subheader(measurement)
            
            with col2:
                # Create a number input for the measurement
                value = st.number_input(
                    f"{measurement} ({MEASUREMENTS[group][measurement]['unit']})",
                    min_value=MEASUREMENTS[group][measurement]['min'],
                    max_value=MEASUREMENTS[group][measurement]['max'],
                    value=st.session_state.measurement_results.get(measurement_key, 0),
                    step=1,
                    key=f"input_{measurement_key}",
                    label_visibility="collapsed",
                    help=f"Enter {measurement} measurement in degrees"
                )
                
                # Store the value in session state
                st.session_state.measurement_results[measurement_key] = value

st.divider()

# Save button with better styling
col1, col2, col3 = st.columns([1, 2, 1])
with col2:
    if st.button("💾 Save Screen Results", type="primary", use_container_width=True):
        # Validate inputs
        validation_errors = validate_inputs(name, event_id, age, weight, height)
        
        if validation_errors:
            st.error("Please fix the following errors:")
            for error in validation_errors:
                st.error(f"• {error}")
        else:
            # Gather all data
            data = {
                "event_id": event_id.strip(),
                "name": name.strip(),
                "age": int(age),
                "date": date.strftime("%Y-%m-%d"),
                "throws": throws,
                "hits": hits,
                "weight": int(weight) if weight > 0 else None,
                "height": height.strip() if height.strip() else None,
                "timestamp": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                "screen_id": str(uuid.uuid4())
            }
            
            # Collect values for each measurement
            for group in MEASUREMENTS:
                for measurement in MEASUREMENTS[group]:
                    # Get the key and value
                    measurement_key = f"{group}_{measurement}"
                    field_key = measurement_key.lower().replace(" ", "_").replace("-", "_").replace("(", "").replace(")", "").replace("/", "_")
                    
                    # Get the measurement value from session state
                    value = st.session_state.measurement_results[measurement_key]
                    data[field_key] = int(value)
            
            # Save data
            saved_file = save_data(data)
            
            if saved_file:
                st.success(f"✅ Screen results saved successfully!")
                st.info(f"File: {saved_file}")
                
                # Show summary
                st.subheader("📊 Assessment Summary")
                summary_cols = st.columns(len(MEASUREMENTS))
                
                for i, group in enumerate(MEASUREMENTS.keys()):
                    with summary_cols[i]:
                        group_measurements = []
                        for measurement in MEASUREMENTS[group]:
                            measurement_key = f"{group}_{measurement}"
                            field_key = measurement_key.lower().replace(" ", "_").replace("-", "_").replace("(", "").replace(")", "").replace("/", "_")
                            value = data[field_key]
                            group_measurements.append(f"{measurement}: {value}°")
                        
                        st.metric(
                            label=f"{group} Measurements",
                            value=f"{len(MEASUREMENTS[group])} recorded",
                            help="\n".join(group_measurements)
                        )

# Add a section to view previous screens
st.divider()
st.subheader("📋 Previous Assessments")

if os.path.exists("data/all_screens.csv"):
    try:
        all_data = pd.read_csv("data/all_screens.csv")
        
        if not all_data.empty:
            # Show a more complete view of the data
            with st.expander("View All Data Columns"):
                st.dataframe(all_data, use_container_width=True)
            
            # Show a simplified view for quick reference
            st.subheader("Recent Assessments")
            basic_columns = ['name', 'event_id', 'date', 'throws', 'hits', 'weight', 'height']
            
            # Add measurement columns if they exist
            for group in MEASUREMENTS:
                for measurement in MEASUREMENTS[group]:
                    measurement_key = f"{group}_{measurement}"
                    field_key = measurement_key.lower().replace(" ", "_").replace("-", "_").replace("(", "").replace(")", "").replace("/", "_")
                    if field_key in all_data.columns:
                        basic_columns.append(field_key)
            
            # Filter to only existing columns
            existing_columns = [col for col in basic_columns if col in all_data.columns]
            
            # Show most recent 10 entries
            recent_data = all_data[existing_columns].tail(10)
            st.dataframe(recent_data, use_container_width=True)
            
            # Show total count
            st.info(f"Total assessments recorded: {len(all_data)}")
        else:
            st.info("No assessment data available yet.")
    
    except Exception as e:
        st.warning(f"Could not load previous assessment data: {e}")
else:
    st.info("No previous assessment data available.")

# Footer
st.divider()
st.markdown("*Softball Mobility Screen - Range of Motion Assessment Tool*") 