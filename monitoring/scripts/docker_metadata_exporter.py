#!/usr/bin/env python3
"""
Docker Metadata Exporter - Expone info de contenedores Docker como métricas Prometheus.
Genera una métrica 'docker_container_info' con labels container_id y container_name.
"""

import docker
from http.server import HTTPServer, BaseHTTPRequestHandler
import time

PORT = 9101

class MetricsHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/metrics':
            self.send_response(200)
            self.send_header('Content-type', 'text/plain; charset=utf-8')
            self.end_headers()
            
            try:
                client = docker.from_env()
                containers = client.containers.list()
                
                output = []
                output.append('# HELP docker_container_info Container metadata (always 1)')
                output.append('# TYPE docker_container_info gauge')
                
                for container in containers:
                    container_id = container.id
                    container_name = container.name
                    # Escapar comillas en el nombre si las hay
                    container_name = container_name.replace('"', '\\"')
                    output.append(f'docker_container_info{{container_id="{container_id}",container_name="{container_name}"}} 1')
                
                self.wfile.write('\n'.join(output).encode('utf-8'))
            except Exception as e:
                self.wfile.write(f'# Error: {e}\n'.encode('utf-8'))
        else:
            self.send_response(404)
            self.end_headers()
    
    def log_message(self, format, *args):
        # Silenciar logs HTTP por defecto
        pass

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', PORT), MetricsHandler)
    print(f'Docker Metadata Exporter listening on port {PORT}')
    server.serve_forever()
