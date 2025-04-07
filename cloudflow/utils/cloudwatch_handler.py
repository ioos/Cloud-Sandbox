import logging
import boto3
import json
from datetime import datetime
from typing import Optional, Dict, Any
from watchtower import CloudWatchLogHandler

class CloudWatchHandler:
    """CloudWatch logging handler for Cloud-Sandbox."""
    
    def __init__(self, user_id: str, job_id: str, haiku_name: str):
        """
        Initializes the CloudWatch handler.

        Parameters
        ----------
        user_id : str
            User identifier.

        job_id : str
            Job identifier.

        haiku_name : str
            Unique run name.
        """
        self.user_id = user_id
        self.job_id = job_id
        self.haiku_name = haiku_name
        
        # Sets up log group and stream names
        self.log_group = f"/cloud-sandbox/users/{user_id}/jobs/{job_id}-{haiku_name}"
        self.stream_name = f"{job_id}-{haiku_name}"
        
        # Initializes the AWS client
        self.client = boto3.client('logs')
        
        # Creat log group if it doesn't exist
        self._ensure_log_group()
        
        # Set up the handler
        self.handler = CloudWatchLogHandler(
            log_group_name=self.log_group,
            log_stream_name=self.stream_name,
            boto3_client=self.client
        )
        
        # Configures logger
        self.logger = logging.getLogger(f"cloudwatch.{user_id}.{job_id}")
        self.logger.setLevel(logging.INFO)
        self.logger.addHandler(self.handler)
        
        # Log initialization
        self.info("CloudWatch logging initialized", {
            "user_id": user_id,
            "job_id": job_id,
            "haiku_name": haiku_name
        })
    
    def _ensure_log_group(self) -> None:
        """Ensure the log group exists, create it if it doesn't."""
        try:
            self.client.create_log_group(logGroupName=self.log_group)
            # Setting retention policy to be 30 days by default
            self.client.put_retention_policy(
                logGroupName=self.log_group,
                retentionInDays=30
            )
        except self.client.exceptions.ResourceAlreadyExistsException:
            # Log group already exists(this should be fine)
            pass
        except Exception as e:
            # Logs the error but doesnt raise it. So that we can continue even if log group creation fails
            print(f"Error creating log group: {str(e)}")
    
    def _format_message(self, message: str, extra: Optional[Dict[str, Any]] = None) -> str:
        """
        Formats the log message with metadata.

        Parameters
        ----------
        message : str
            The log message.

        extra : dict, optional
            Additional metadata to include.

        Returns
        -------
        str
            JSON string containing formatted log message.
        """
        log_data = {
            "timestamp": datetime.utcnow().isoformat(),
            "message": message,
            "user_id": self.user_id,
            "job_id": self.job_id,
            "haiku_name": self.haiku_name
        }
        
        if extra:
            log_data.update(extra)
            
        return json.dumps(log_data)
    
    def info(self, message: str, extra: Optional[Dict[str, Any]] = None) -> None:
        """Logs an info message.
    
        Parameters
        ----------
        message : str
            The log message.

        extra : dict, optional
            Additional metadata to include.
        """
        self.logger.info(self._format_message(message, extra))
    
    def warning(self, message: str, extra: Optional[Dict[str, Any]] = None) -> None:
        """Logs a warning message."""
        self.logger.warning(self._format_message(message, extra))
    
    def error(self, message: str, extra: Optional[Dict[str, Any]] = None) -> None:
        """Logs an error message."""
        self.logger.error(self._format_message(message, extra))
    
    def debug(self, message: str, extra: Optional[Dict[str, Any]] = None) -> None:
        """Logs a debug message."""
        self.logger.debug(self._format_message(message, extra))
    
    def cleanup(self) -> None:
        """Cleans up the resources used by the handler."""
        try:
            self.logger.removeHandler(self.handler)
            self.handler.close()
            self.info("CloudWatch logging cleanup completed")
        except Exception as e:
            print(f"Error during cleanup: {str(e)}") 