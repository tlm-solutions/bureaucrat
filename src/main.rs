#![deny(missing_docs)]
//!
//! This is bureaucrat the service which maintains the data inside the redis
//!

use std::env;

use redis::cluster::ClusterClient;
use redis::Commands;

use std::time::SystemTime;
use tlms::grpc::receive_waypoint_server::{ReceiveWaypoint, ReceiveWaypointServer};
use tlms::grpc::{GrpcWaypoint, ReturnCode};
use tlms::locations::waypoint::Waypoint;

use log::{error, info};
use tonic::{transport::Server, Request, Response, Status};

/// this function reads the uri specifier for the redis instance from env variables
pub fn get_redis_uri() -> String {
    let default_redis_port = "6379".to_string();
    let default_redis_host = "127.0.0.1".to_string();

    format!(
        "redis://{}:{}",
        std::env::var("REDIS_HOST").unwrap_or(default_redis_host),
        std::env::var("REDIS_PORT").unwrap_or(default_redis_port)
    )
}

/// returns the redis connection pool
pub fn connect_to_redis() -> Option<ClusterClient> {
    let redis_uri = vec![get_redis_uri()];
    ClusterClient::new(redis_uri).ok()
}

/// service struct holding the redis connection pool
#[derive(Clone)]
pub struct Bureaucrat {
    redis_connection_pool: ClusterClient,
}

impl Bureaucrat {
    fn new() -> Option<Bureaucrat> {
        connect_to_redis().map(|pool| Bureaucrat {
            redis_connection_pool: pool,
        })
    }
}

#[tonic::async_trait]
impl ReceiveWaypoint for Bureaucrat {
    async fn receive_waypoint(
        &self,
        request: Request<GrpcWaypoint>,
    ) -> Result<Response<ReturnCode>, Status> {
        let extracted = request.into_inner();

        info!("received waypoint {:?}", &extracted);
        let region = extracted.region;

        let mut redis_connection = match self.redis_connection_pool.get_connection() {
            Ok(value) => value,
            Err(e) => {
                error!("cannot fetch redis connection {:?}", e);
                return Err(Status::internal("cannot get redis connection!"));
            }
        };

        let waypoints_strings: Vec<String> =
            match redis_connection.get(format!("r{}", extracted.region)) {
                Ok(value) => value,
                Err(_) => Vec::new(),
            };

        let now = match SystemTime::now().duration_since(SystemTime::UNIX_EPOCH) {
            Ok(n) => n.as_millis(),
            Err(_) => panic!("SystemTime before UNIX EPOCH!"),
        };

        const TIME_THRESHOLD: u128 = 1000 * 60 * 5;

        let mut waypoints: Vec<Waypoint> = waypoints_strings
            .iter()
            .map(|x| serde_json::from_str(x).unwrap())
            .collect::<Vec<Waypoint>>();

        waypoints.retain(|x| now - (x.time as u128) < TIME_THRESHOLD);
        waypoints.push(Waypoint::from(extracted));

        let string_waypoints: Vec<String> = waypoints
            .iter()
            .map(|x| serde_json::to_string(x).unwrap())
            .collect();

        let key: String = format!("r{}", region);
        match redis::cmd("SET")
            .arg(key)
            .arg(string_waypoints)
            .query(&mut redis_connection)
        {
            Ok(()) => Ok(Response::new(ReturnCode { status: 0 })),
            Err(e) => {
                error!("cannot insert list of waypoints into redis {:}", e);
                Err(Status::internal("cannot get redis connection!"))
            }
        }
    }
}

#[tokio::main]
async fn main() -> std::io::Result<()> {
    env_logger::init();

    info!("Starting the bureaucrating service ... ");

    let default_grpc_bureaucrat_host = String::from("127.0.0.1:50053");
    let grpc_bureaucrat_host = env::var("BUREAUCRABUREAUCRATT_HOST")
        .unwrap_or(default_grpc_bureaucrat_host)
        .parse()
        .expect("cannot fetch bureaucrat host!");

    info!(
        "the bureaucrat receives its papaer work on {} ... ",
        &grpc_bureaucrat_host
    );
    let bureaucrat = Bureaucrat::new().expect("cannot create bureaucrat grpc server");

    Server::builder()
        .add_service(ReceiveWaypointServer::new(bureaucrat))
        .serve(grpc_bureaucrat_host)
        .await
        .expect("grpc server stopped");

    Ok(())
}
