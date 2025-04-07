"""Simple script to verify CloudWatch logging functionality."""

import os
import time
from cloudflow.utils.cloudwatch_handler import CloudWatchHandler
from haikunator import Haikunator

def main():
    """Test CloudWatch logging functionality."""
    # Generate a unique run name
    haikunator = Haikunator()
    run_name = haikunator.haikunate()
    
    # Initialize handler
    handler = CloudWatchHandler(
        user_id=os.getenv('USER', 'test-user'),
        job_id='test-job',
        haiku_name=run_name
    )
    
    try:
        # Test different log levels
        print(f"Testing CloudWatch logging with run name: {run_name}")
        
        # Basic info log
        handler.info("Starting test run", {"test": "basic info"})
        
        # Warning with extra data
        handler.warning("Resource usage high", {"cpu": 85, "memory": "70%"})
        
        # Error with stack trace
        try:
            raise ValueError("Test error")
        except Exception as e:
            handler.error("Caught exception", {"error": str(e), "type": type(e).__name__})
        
        # Debug message
        handler.debug("Detailed debug info", {"step": "complete"})
        
        print("\nLogs sent successfully!")
        print(f"Check CloudWatch console for logs in group: /cloud-sandbox/users/{os.getenv('USER', 'test-user')}/jobs/test-job-{run_name}")
        print("Note: It may take a few minutes for logs to appear in CloudWatch")
        
    finally:
        # Clean up
        handler.cleanup()
        print("\nCleanup completed")

if __name__ == "__main__":
    main() 