# 🥎 Softball Mobility Screen

A streamlined web application for recording and tracking softball player mobility assessments. Built with Streamlit for easy deployment and use.

## 📊 Features

- **Range of Motion Assessment**: Record precise measurements for hips, thoracic spine, and shoulders
- **Data Export**: Automatic CSV export for analysis
- **Real-time Validation**: Input validation to ensure data quality
- **Historical Tracking**: View previous assessments and trends
- **Mobile Friendly**: Responsive design works on tablets and mobile devices

## 🎯 Measurements Tracked

### Hips
- Right Hip External Rotation (ER)
- Right Hip Internal Rotation (IR)
- Left Hip External Rotation (ER)
- Left Hip Internal Rotation (IR)

### Thoracic Spine (Tspine)
- Thoracic Spine Rotation Left
- Thoracic Spine Rotation Right

### Shoulders
- Right Shoulder External Rotation (ER)
- Right Shoulder Internal Rotation (IR)
- Left Shoulder External Rotation (ER)
- Left Shoulder Internal Rotation (IR)
- Right Shoulder Flexion (Flx)
- Left Shoulder Flexion (Flx)

## 🚀 Quick Start

### Local Development
```bash
# Clone the repository
git clone https://github.com/cseval/movement-screen.git
cd movement-screen

# Install dependencies
pip install -r requirements.txt

# Run the application
streamlit run screen_main.py
```

### Streamlit Cloud Deployment
1. Fork this repository
2. Go to [share.streamlit.io](https://share.streamlit.io)
3. Connect your GitHub account
4. Deploy from your forked repository

## 📋 Usage

1. **Enter Athlete Information**: Fill in event ID, name, age, and physical details
2. **Record Measurements**: Use the tabbed interface to enter range of motion values in degrees
3. **Validate Data**: The app will check for required fields and reasonable values
4. **Save Assessment**: Click "Save Screen Results" to store the data
5. **Review Data**: View previous assessments in the historical data section

## 💾 Data Storage

- Individual assessments saved as JSON files in `/data` directory
- Consolidated data exported to `data/all_screens.csv`
- Includes timestamps and unique IDs for tracking

## 🛠️ Technical Details

- **Framework**: Streamlit
- **Data Processing**: Pandas
- **File Formats**: JSON, CSV
- **Python Version**: 3.7+

## 📊 Data Fields

| Field | Description | Type |
|-------|-------------|------|
| event_id | Event or session identifier | String |
| name | Athlete name | String |
| age | Athlete age | Integer |
| date | Assessment date | Date |
| throws/hits | Throwing/hitting preference | String |
| weight | Body weight (lbs) | Integer |
| height | Height measurement | String |
| *_measurements | Range of motion values (degrees) | Integer |

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Commit your changes (`git commit -am 'Add new feature'`)
4. Push to the branch (`git push origin feature/improvement`)
5. Create a Pull Request

## 📝 License

This project is open source and available under the [MIT License](LICENSE).

## 📞 Support

For questions or support, please open an issue on GitHub or contact the development team.